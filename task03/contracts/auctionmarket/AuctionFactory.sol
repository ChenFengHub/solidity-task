// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./Auction.sol";

// Uniswap V2 的工厂模式
contract AuctionFactory {

    Auction[] public auctions;
    uint256 public auctionsIndex = 0;
    address internal owner;

    constructor(address _owner) {
        owner = _owner;
    }

    function createAuction(address _owner,
                           address _seller, 
                           uint256 _startPrice, 
                           address _nftContract, 
                           uint256 _nftTokenId, 
                           uint256 _duration, 
                           address _tokenAddress) public returns(uint256) {
        require(_owner == owner, "Only owner can create auction");
        Auction auction = new Auction(owner, _seller, block.timestamp, _startPrice, 
                                _nftContract, _nftTokenId, _duration, _tokenAddress);
        auctions.push(auction);
        return auctionsIndex++;
    }

    function getAuction(uint256 _auctionsIndex) public view returns(Auction) {
        require(_auctionsIndex < auctionsIndex, "Auction does not exist");
        return auctions[_auctionsIndex];
    }
}