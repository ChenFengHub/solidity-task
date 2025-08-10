// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./AuctionFactory.sol";
import "./Auction.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract AuctionMarket is Initializable, UUPSUpgradeable {

    Auction public curAuction;

    address owner;

    AuctionFactory auctionFactory = new AuctionFactory(msg.sender);

    constructor() {
        owner = msg.sender;
    }

    function initialize() public {
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

    // 使用 ether 竞拍
    function partInAuction(address _buyer) external payable {
        curAuction.partInAuction{value: msg.value}(_buyer);
    }
    // 使用 erc20 竞拍
    function partInAuctionWithERC20(address _buyer, uint256 erc20Amount, address _tokenAddress) external {
        curAuction.partInAuctionWithERC20(_buyer, erc20Amount, _tokenAddress);
    }

    // 结束拍卖
    function endAuction() external {
        require(msg.sender == owner, "Only owner can end auction");
        curAuction.endAuction(owner);
    }

    //  代理合约调用 upgradeTo(address)）并通过 delegatecall 触发方法
    //  逻辑合约中的_authorizeUpgrade(address)
    function _authorizeUpgrade(address) internal view override {
        // 只有管理员可以升级合约
        require(msg.sender == owner, "Only owner can upgrade");
    }

}