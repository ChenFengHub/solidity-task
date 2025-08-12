// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./AuctionFactory.sol";
import "./Auction.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract AuctionMarketV2 is Initializable, UUPSUpgradeable {

    Auction public curAuction;

    address owner;

    AuctionFactory public auctionFactory;


    // constructor() {
    //     owner = msg.sender;
    // }

    function initialize() public {
        owner = msg.sender;
    }

    function setAuctionFactory(address _auctionFactory) public {
        require(msg.sender == owner, "Only owner can set auction factory");
        auctionFactory = AuctionFactory(_auctionFactory);
        auctionFactory.setOwner(owner);
    }

    function createAuctoin(address _seller, 
                           uint256 _startPrice, 
                           address _nftContract, 
                           uint256 _nftTokenId, 
                           uint256 _duration, 
                           address _tokenAddress) public returns(uint256) {
        require(address(auctionFactory) != address(0), "Auction factory not set");
        require(owner == msg.sender, "Only owner can create auction");
        require(address(curAuction) == address(0) || curAuction.hasEnded(), "auction has not end,can not create new auctoin");
        uint256 index = auctionFactory.createAuction(owner, _seller, _startPrice, _nftContract, _nftTokenId, _duration, _tokenAddress);
        curAuction = auctionFactory.getAuction(index);
        return index;
    }

    // 使用 ether 竞拍
    function partInAuction(address _buyer) external payable {
        require(address(curAuction) != address(0), "Auction does not exist");
        curAuction.partInAuction{value: msg.value}(_buyer);
    }
    // 使用 erc20 竞拍
    function partInAuctionWithERC20(address _buyer, uint256 erc20Amount, address _tokenAddress) external {
        require(address(curAuction) != address(0), "Auction does not exist");
        curAuction.partInAuctionWithERC20(_buyer, erc20Amount, _tokenAddress);
    }

    // 结束拍卖
    function endAuction() external {
        require(address(curAuction) != address(0), "Auction does not exist");
        require(msg.sender == owner, "Only owner can end auction");
        curAuction.endAuction(owner);
    }

    // 结束拍卖(以跨链实现NFT的转移)
    function endAuctionWithCrossChain() external {
        require(address(curAuction) != address(0), "Auction does not exist");
        require(msg.sender == owner, "Only owner can end auction");
        curAuction.endAuctionWithCrossChain(owner);
    }

    // 获得当前最高价（美金）
    function getHighestBidUDS() public view returns(uint256) {
        require(address(curAuction) != address(0), "Auction does not exist");
        return curAuction.getHighestBidUDS();
    }
    
    // 获取当前拍卖的手续费
    function getFeeAmount() external view returns (uint256) {
        require(address(curAuction) != address(0), "Auction does not exist");
        return curAuction.getFeeAmount();
    }
    
    // 获取seller获得的金额
    function getSellerProceeds() external view returns (uint256) {
        require(address(curAuction) != address(0), "Auction does not exist");
        return curAuction.getSellerProceeds();
    }

    function setReceiverAddress(address _receiverAddress) external {
        require(address(curAuction) != address(0), "Auction does not exist");
        curAuction.setReceiverAddress(_receiverAddress);
    }

    function getReceiverAddress() external view returns (address) {
        require(address(curAuction) != address(0), "Auction does not exist");
        return curAuction.receiverAddress();
    }

    function setRouter(address _router) external {
        require(address(curAuction) != address(0), "Auction does not exist");
        curAuction.setRouter(_router);
    }

    //  代理合约调用 upgradeTo(address)）并通过 delegatecall 触发方法
    //  逻辑合约中的_authorizeUpgrade(address)
    function _authorizeUpgrade(address) internal view override {
        // 只有管理员可以升级合约
        require(msg.sender == owner, "Only owner can upgrade");
    }

    function test() public returns(string memory){ 
        return "test";
    }       

}