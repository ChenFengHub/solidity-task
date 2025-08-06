// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";


contract Auction {

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
    // 代币类型：address(0)-ehter;其他值-对应ERC20，比如USDC（一种与美元挂钩的稳定币，USDC/USC接近1:1）
    address internal tokenAddress;

    constructor(address _admin, 
                address _seller, 
                uint256 _startTime, 
                uint256 _startPrice, 
                address _nftContract, 
                uint256 _nftTokenId, 
                uint256 _duration, 
                address _tokenAddress) {
        require(_admin != address(0), "Owner address cannot be zero");
        require(_admin == msg.sender, "Seller address cannot be zero");
        require(_nftContract != address(0), "NFT contract address cannot be zero");
        
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
    }

    // 参与竞拍
    function partInAuction(address _buyer, uint256 _amount) external {
        require(_buyer != address(0), "Invalid buyer address");
        require(_buyer != admin, "Admin cannot be the seller");
        require(block.timestamp >= startTime && block.timestamp <= startTime + duration && !ended, "Auction period has ended");
        
        // 需要添加币对转换为美元比较大小。包括：初始起拍价以及竞拍价都要转换后比较
        
        require(_amount > highestBid, "Bid amount must be higher than the current highest bid");
        
        
        if (highestBidder != address(0)) {
            if (tokenAddress == address(0)) {
                payable(highestBidder).transfer(highestBid);
            } else {
                // ERC20，比如USDC。可能还要考虑跨链？暂时不考虑
                IERC20(tokenAddress).transfer(highestBidder, highestBid);
            }
        }
        
        highestBid = _amount;
        highestBidder = _buyer;
    }

    // 结束拍卖
    function endAuction(address _admin) external {
        require(admin == _admin, "Only Admin can end auction");
        // 正常要等拍卖时间到了，才能结束拍卖，这里简单处理
        // 1. 将拍品转移给最高出价者
        IERC721(nftContract).safeTransferFrom(admin, highestBidder, nftTokenId);
        // 2. 将钱转给卖家
        if (tokenAddress == address(0)) {
            payable(seller).transfer(highestBid);
        } else {
            IERC20(tokenAddress).transferFrom(highestBidder, seller, highestBid);
        }
    }
    

}

