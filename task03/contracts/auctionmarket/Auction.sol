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
        // 需要让卖家预先授权合约部署地址，这样当前合约才可以操作进行转移（如下操作是需要前端执行）
        // 卖家调用（前端或脚本）
        // IERC721(nftContract).approve(address(this), nftTokenId);
        // 或授权所有 NFT
        // IERC721(nftContract).setApprovalForAll(msg.sender, true);
        // NFTBid(address(nftContract)).forceTransfer(seller, highestBidder, nftTokenId);
        IERC721(nftContract).safeTransferFrom(seller, highestBidder, nftTokenId);
        
        // 2. 将钱转给卖家
        if (tokenAddress == address(0)) {
            payable(seller).transfer(highestBid);
        } else {
            IERC20(tokenAddress).transferFrom(highestBidder, seller, highestBid);
        }
        ended = true;
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

