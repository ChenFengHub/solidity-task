// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
import "../bid/NFTBid.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../erc20/MyToken.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";

contract Auction {
    using Strings for uint256;
    address internal admin;
    address internal seller;
    // 拍品（NFT）的合约地址
    address internal nftContract;
    uint256 internal nftTokenId;
    uint256 internal startTime = 0;
    // 初始价格。保存转化后的美金
    uint256 internal startPrice = 0;
    uint256 internal duration = 0;
    bool internal ended = false;
    // 最高交易金额。保存转化后的美金
    uint256 internal highestBid = 0;
    address internal highestBidder = address(0);
    // 代币地址：address(0)-ehter;其他值-对应ERC20合约地址
    address internal tokenAddress;

    // 补充信息：
    // ETH/USD address：0x694AA1769357215DE4FAC081bf1f309aDC325306
    // USDC/USD address：0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E
    AggregatorV3Interface internal ethPriceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306); // ETH/USD 价格预言机
    AggregatorV3Interface internal erc20PriceFeed = AggregatorV3Interface(0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E); // ERC20/USD 价格预言机
    // 价格预言机小数位数
    uint8 internal ethPriceFeedDecimals;
    uint8 internal erc20PriceFeedDecimals;
    // 默认价格值
    int256 public defaultETHPrice = 3000 * 10**8;   // 3000 USD with 8 decimals
    int256 public defaultERC20Price = 1 * 10**8;    // 1 USD with 8 decimals

    // 手续费相关变量
    uint256 internal feeAmount = 0;        // 手续费金额
    uint256 internal sellerProceeds = 0;   

    // 跨链信息
    IRouterClient public i_router;
    address public routerAddress = 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59; // 默认是sepolia测试网路由地址
    uint64 public chainSelector = 16015286601757825753;   // 默认是sepolia测试网链选择器地址
    address public receiverAddress;   // 接收合约的地址

    event CrossChainTransferStarted(
        address nftContract,
        uint256 nftTokenId,
        address receiverAddress,
        uint64 chainSelector
    );

    event CrossChainMessageSent(bytes32 messageId);
    
    constructor(address _admin, 
                address _seller, 
                uint256 _startTime, 
                uint256 _startPrice, 
                address _nftContract, 
                uint256 _nftTokenId, 
                uint256 _duration, 
                address _tokenAddress) {
        require(_admin != address(0), "Owner address cannot be zero");
        require(_nftContract != address(0), "NFT contract address cannot be zero");
        require(IERC721(_nftContract).ownerOf(_nftTokenId) == _seller, "Seller must own NFT");
        
        admin = _admin;

        if (_seller != address(0)) {
            seller = _seller;
        } else {
            seller = msg.sender;
        }

        if (_startTime != 0) {
            startTime = _startTime;
        } else {
            startTime = block.timestamp;
        }

        if (_duration != 0) {
            duration = _duration;
        } else {
            duration = 1 days;
        }
        
        nftContract = _nftContract;
        nftTokenId = _nftTokenId;
        startPrice = _startPrice;
        tokenAddress = _tokenAddress;

        // 初始化预言机的小数位数
        initializePriceFeedDecimals();
    }

    // 该合约需要有接收ether的能力，用于跨链支付
    receive() external payable {
        // 确保接收到的金额大于0
        require(msg.value > 0, "Received value must be greater than 0");
    }

    // 跨链相关方法。_router是发送方部署测试网络的ccip 路由地址
    function setRouter(address _router) public {
        i_router = IRouterClient(_router);
    }
    function setChainSelector(uint64 _chainSelector) public {
        chainSelector = _chainSelector;
    }
    function setRouterAddress(address _routerAddress) public {
        routerAddress = _routerAddress;
    }
    function setReceiverAddress(address _receiverAddress) public {
        receiverAddress = _receiverAddress;
    }

    // 获取当前最高的出价者的出价（美金展示）
    function getHighestBidUDS() public view returns(uint256) {
        if (highestBid == 0) {
            return 0;
        }

        if (tokenAddress == address(0)) {
            return convertETHToUSD(highestBid);
        } else {
            return convertERC20ToUSD(highestBid);
        }
    }

    function hasEnded() public view returns(bool) {
        return ended;
    }


    // 参与竞拍（采用ether进行交易）
    function partInAuction(address _buyer) external payable {
        require(_buyer != address(0), "Invalid buyer address");
        require(_buyer != admin, "Admin cannot be the seller");
        require(block.timestamp >= startTime && block.timestamp <= startTime + duration && !ended, "Auction period has ended");
        
        // 需要添加币对转换为美元比较大小。包括：初始起拍价以及竞拍价都要转换后比较
        uint256 newHighestPrice = convertETHToUSD(msg.value);
        uint256 transferStartPrice = convertETHToUSD(startPrice);
    
        require(newHighestPrice > transferStartPrice, 
            string.concat("Bid amount must be higher than the startPrice. Bid USD: ", 
                newHighestPrice.toString(), 
                ", Start price USD: ", 
                transferStartPrice.toString()
            )
        );
        if (highestBidder != address(0)) {
            uint256 oldHighestPrice;
            if (tokenAddress == address(0)) {
                oldHighestPrice = convertETHToUSD(highestBid);
            } else {
                oldHighestPrice = convertERC20ToUSD(highestBid);
            }
            require(newHighestPrice > oldHighestPrice, string.concat(
                    "Bid amount must be higher than the current highest bid.Bid USD:",
                    newHighestPrice.toString(), 
                    ",Current Highest bid USD:", 
                    oldHighestPrice.toString()
                    )
            );
        }
        
        
        if (highestBidder != address(0)) {
            if (tokenAddress == address(0)) {
                payable(highestBidder).transfer(highestBid);
            } else {
                // ERC20，比如USDC。可能还要考虑跨链？暂时不考虑
                IERC20(tokenAddress).transfer(highestBidder, highestBid);
            }
        }
        
        highestBid = msg.value;
        highestBidder = _buyer;
        tokenAddress = address(0);
    }

    function partInAuctionWithERC20(address _buyer, uint256 erc20Amount, address _tokenAddress) external {
        require(_buyer != address(0), "Invalid buyer address");
        require(_buyer != admin, "Admin cannot be the seller");
        require(block.timestamp >= startTime && block.timestamp <= startTime + duration && !ended, "Auction period has ended");
        
        require(MyToken(_tokenAddress).balanceOf(_buyer) > erc20Amount, "Account ERC20 balance is insufficient");

        // 需要添加币对转换为美元比较大小。包括：初始起拍价以及竞拍价都要转换后比较
        uint256 newHighestPrice = convertERC20ToUSD(erc20Amount);
        uint256 transferStartPrice = convertETHToUSD(startPrice);
    
        require(newHighestPrice > transferStartPrice, 
            string.concat("Bid amount must be higher than the startPrice. Bid USD: ", 
                newHighestPrice.toString(), 
                ", Start price USD: ", 
                transferStartPrice.toString()
            )
        );
        if (highestBidder != address(0)) {
            uint256 oldHighestPrice;
            if (tokenAddress == address(0)) {
                oldHighestPrice = convertETHToUSD(highestBid);
            } else {
                oldHighestPrice = convertERC20ToUSD(highestBid);
            }
            require(newHighestPrice > oldHighestPrice, string.concat(
                    "Bid amount must be higher than the current highest bid.Bid USD:",
                    newHighestPrice.toString(), 
                    ",Current Highest bid USD:", 
                    oldHighestPrice.toString()
                    )
            );
        }
        
        
        if (highestBidder != address(0)) {
            if (tokenAddress == address(0)) {
                payable(highestBidder).transfer(highestBid);
            } else {
                // ERC20，比如USDC。可能还要考虑跨链？暂时不考虑
                IERC20(tokenAddress).transfer(highestBidder, highestBid);
            }
        }
        
        highestBid = erc20Amount;
        highestBidder = _buyer;
        tokenAddress = _tokenAddress;  // 直接赋值 USDC/USD 的priceFeed地址
    }
    

    // 结束拍卖
    function endAuction(address _admin) external {
        require(ended == false, "Auction has ended");
        require(admin == _admin, "Only Admin can end auction");
        // 正常要等拍卖时间到了，才能结束拍卖，这里简单处理
        // 1. 将拍品转移给最高出价者（拍品从拍品拥有者seller转移到竞拍得主）
        // 该方法需要seller授权给当前协议，才能进行。这个前端进行该操作
        IERC721(nftContract).safeTransferFrom(seller, highestBidder, nftTokenId);
        
        feeAmount = calculateDynamicFeeByToken(highestBid, tokenAddress);
        sellerProceeds = highestBid - feeAmount;

        // 2. 将钱转给卖家
        if (tokenAddress == address(0)) {
            payable(seller).transfer(sellerProceeds);
            if (feeAmount > 0) {
                payable(admin).transfer(feeAmount);
            }
        } else {
            // 该方法需要seller授权给当前协议，才能进行。这个前端进行该操作
            IERC20(tokenAddress).transferFrom(highestBidder, seller, highestBid);
            if (feeAmount > 0) {
                IERC20(tokenAddress).transferFrom(highestBidder, admin, feeAmount);
            }
        }
        ended = true;
    }

    // 结束拍卖(以跨链实现NFT的转移)
    function endAuctionWithCrossChain(address _admin) external {
        // 添加调试事件
        emit CrossChainTransferStarted(
            nftContract,
            nftTokenId,
            receiverAddress,
            chainSelector
        );

        require(ended == false, "Auction has ended");
        require(admin == _admin, "Only Admin can end auction");
        require(receiverAddress != address(0), "Invalid receiver address");
        require(chainSelector != 0, "Invalid chain selector");
        require(address(i_router) != address(0), "Invalid router address");

        // 将NFT转移到NFT中，则原用户不再拥有该NFT，认为被锁定/销毁
        IERC721(nftContract).safeTransferFrom(seller, address(this), nftTokenId);
    

        // 2. 构造CCIP消息（包含NFT元数据）
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiverAddress), 
            data: abi.encode(nftContract, nftTokenId, highestBid, "test"), // 传递关键数据
            tokenAmounts: new Client.EVMTokenAmount[](0),          // 无代币转移
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 3_300_000})),
            feeToken: address(0) // 用原生代币（如ETH）支付手续费
        });

        // 3. 计算手续费并发送跨链消息
        uint256 fee = i_router.getFee(chainSelector, message);
        require(address(this).balance >= fee, "Insufficient fee");
        // 发送跨链消息
        bytes32 messageId = i_router.ccipSend(chainSelector, message);
        emit CrossChainMessageSent(messageId);

        feeAmount = calculateDynamicFeeByToken(highestBid, tokenAddress);
        sellerProceeds = highestBid - feeAmount;

        // 2. 将钱转给卖家
        if (tokenAddress == address(0)) {
            payable(seller).transfer(sellerProceeds);
            if (feeAmount > 0) {
                payable(admin).transfer(feeAmount);
            }
        } else {
            // 该方法需要seller授权给当前协议，才能进行。这个前端进行该操作
            IERC20(tokenAddress).transferFrom(highestBidder, seller, highestBid);
            if (feeAmount > 0) {
                IERC20(tokenAddress).transferFrom(highestBidder, admin, feeAmount);
            }
        }
        ended = true;
    }

    // 获取当前拍卖的手续费
    function getFeeAmount() external view returns (uint256) {
        return feeAmount;
    }
    
    // 获取seller获得的金额
    function getSellerProceeds() external view returns (uint256) {
        return sellerProceeds;
    }

    // 计算手续费。小于1则为0
    function calculateDynamicFeeByToken(uint256 amount, address _tokenAddress) internal view returns (uint256) {
        if (_tokenAddress == address(0)) {
            return calculateDynamicFee(amount);
        } else {
            // 为了防止因为进度丢失导致结果变成0，amout * 10^18
            uint256 toEth = convertERC20ToETH(amount * 10 ** 18);
            uint256 feeEthAmout = calculateDynamicFee(toEth);
            return convertETHToERC20(feeEthAmout) / 10 ** 18;
        }
    }

    // 动态手续费计算函数
    function calculateDynamicFee(uint256 amount) internal pure returns (uint256) {
        // 动态手续费规则：
        // < 1 ETH: 5% fee
        // 1-5 ETH: 4% fee
        // 5-10 ETH: 3% fee
        // > 10 ETH: 2% fee
        
        if (amount < 1 ether) {
            return (amount * 5) / 100;  // 5%
        } else if (amount < 5 ether) {
            return (amount * 4) / 100;  // 4%
        } else if (amount < 10 ether) {
            return (amount * 3) / 100;  // 3%
        } else {
            return (amount * 2) / 100;  // 2%
        }
    }

    function convertETHToERC20(uint256 ethAmount) internal view returns (uint256) {
        int256 ethPrice = getETHPrice();
        int256 erc20Price = getERC20Price();
        return (ethAmount * uint256(ethPrice)) / uint256(erc20Price);
    }

    function convertERC20ToETH(uint256 erc20Amount) internal view returns (uint256) {
        int256 ethPrice = getETHPrice();
        int256 erc20Price = getERC20Price();
        return (erc20Amount * uint256(erc20Price)) / uint256(ethPrice);
    }
    
     // 获取ETH对USD的当前价格
    function getETHPrice() private view returns (int256) {
        // 检查价格预言机地址是否有效
        if (address(ethPriceFeed) == address(0)) {
            return defaultETHPrice;
        }
        
        // 检查目标地址是否有代码
        address ethPriceFeedAddress = address(ethPriceFeed);
        uint256 size;
        assembly {
            size := extcodesize(ethPriceFeedAddress)
        }
         
        if (size == 0) {
            return defaultETHPrice;
        }

        // 使用低级调用来避免直接调用错误
        (bool success, bytes memory data) = ethPriceFeedAddress.staticcall(
            abi.encodeWithSignature("latestRoundData()")
        );

        if (!success) {
            return defaultETHPrice;
        }

        // 检查数据长度是否足够
        if (data.length < 32 * 5) {
            return defaultETHPrice;
        }

        // 解析返回数据
        (, int256 price, ,  , ) = 
            abi.decode(data, (uint80, int256, uint256, uint256, uint80));
        
        // 检查返回的价格是否有效
        if (price <= 0) {
            return defaultETHPrice;
        }
        return price;
    }

    // 获取ERC20对USD的当前价格
    function getERC20Price() private view returns (int256) {
        // 检查价格预言机地址是否有效
        if (address(erc20PriceFeed) == address(0)) {
            return defaultERC20Price;
        }
        
        // 检查目标地址是否有代码
        address erc20PriceFeedAddress = address(erc20PriceFeed);
        uint256 size;
        assembly {
            size := extcodesize(erc20PriceFeedAddress)
        }
        
        if (size == 0) {
            return defaultERC20Price;
        }

        // 使用低级调用来避免直接调用错误
        (bool success, bytes memory data) = erc20PriceFeedAddress.staticcall(
            abi.encodeWithSignature("latestRoundData()")
        );

        if (!success) {
            return defaultERC20Price;
        }

        // 检查数据长度是否足够
        if (data.length < 32 * 5) {
            return defaultERC20Price;
        }

        // 解析返回数据
        (, int256 price, ,  , ) = abi.decode(data, (uint80, int256, uint256, uint256, uint80));
        
        // 检查返回的价格是否有效
        if (price <= 0) {
            return defaultERC20Price;
        }
        return price;
    }

    // 将ETH金额转换为USD价值（18位小数）（精度只到1美金，小于1美金的差值无法体现）
    function convertETHToUSD(uint256 ethAmount) private view returns (uint256) {
        int256 price = getETHPrice();
        // ETH通常有18位小数，价格预言机小数位数需要处理
        // USD价值 = ETH数量 * ETH价格 / (10 ** 价格预言机小数位数)
        return (ethAmount * uint256(price)) / (10 ** ethPriceFeedDecimals) / (10 ** 18);
    }

    // 将ERC20金额转换为USD价值（18位小数）（精度只到1美金，小于1美金的差值无法体现）
    function convertERC20ToUSD(uint256 erc20Amount) private view returns (uint256) {
        int256 price = getERC20Price();
        // ERC20价值 = ERC20数量 * ERC20价格 / (10 ** 价格预言机小数位数)
        return (erc20Amount * uint256(price)) / (10 ** erc20PriceFeedDecimals);
    }

     // 安全地获取预言机小数位数
    function getDecimalsSafely(AggregatorV3Interface priceFeed) private view returns (uint8) {
        // 检查地址是否有效
        if (address(priceFeed) == address(0)) {
            return 8; // 默认值
        }
        
        // 检查合约代码是否存在
        uint256 size;
        address priceFeedAddress = address(priceFeed);
        assembly {
            size := extcodesize(priceFeedAddress)
        }
        
        if (size == 0) {
            return 8; // 默认值
        }
        
        // 使用低级调用获取小数位数
        (bool success, bytes memory data) = priceFeedAddress.staticcall(
            abi.encodeWithSignature("decimals()")
        );
        
        if (!success || data.length < 32) {
            return 8; // 默认值
        }
        
        // 解析返回值
        uint8 decimals = abi.decode(data, (uint8));
        return decimals;
    }
    
    // 初始化预言机小数位数
    function initializePriceFeedDecimals() private {
        ethPriceFeedDecimals = getDecimalsSafely(ethPriceFeed);
        erc20PriceFeedDecimals = getDecimalsSafely(erc20PriceFeed);
    }

}

