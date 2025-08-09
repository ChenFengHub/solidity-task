// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./AuctionFactory.sol";
import "./Auction.sol";

contract AuctionMarket {

    Auction public curAuction;

    address owner;

    AuctionFactory auctionFactory = new AuctionFactory(msg.sender);

    constructor() {
        owner = msg.sender;
    }

    function createAuctoin(address _seller, 
                           uint256 _startPrice, 
                           address _nftContract, 
                           uint256 _nftTokenId, 
                           uint256 _duration, 
                           address _tokenAddress) public returns(uint256) {
        require(owner == msg.sender, "Only owner can create auction");
        require(address(curAuction) == address(0) || curAuction.hasEnded(), "auction has not end,can not create new auctoin");
        uint256 index = auctionFactory.createAuction(owner, _seller, _startPrice, _nftContract, _nftTokenId, _duration, _tokenAddress);
        curAuction = auctionFactory.getAuction(index);
        return index;
    }

    function partInAuction(address _buyer) external payable {
        curAuction.partInAuction{value: msg.value}(_buyer);
    }

    // 结束拍卖
    function endAuction() external {
        require(msg.sender == owner, "Only owner can end auction");
        curAuction.endAuction(owner);
    }

}