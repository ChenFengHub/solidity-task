// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BeggingContract {

    address private owner;
    mapping(address donator => uint256 amount) private donations;
    uint256 private donationStartTime;
    uint256 private donationDuration = 1 days;

    event Donation(address indexed donator, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    function setDonationTime(uint256 _startTime, uint256 _duration) external {
        require(msg.sender == owner, "Only owner can set donation time");
        if (_startTime == 0) {
            _startTime = block.timestamp;
        }
        if (_duration == 0) {
            _duration = 1 days;
        }
        donationStartTime = _startTime;
        donationDuration = _duration;
    }

    function donate() external payable {
        require(block.timestamp >= donationStartTime && block.timestamp <= donationStartTime + donationDuration, "Donation period has ended");
        donations[msg.sender] += msg.value;
    }

    function withdraw() external {
        require(msg.sender == owner, "You are not the owner");
        payable(owner).transfer(address(this).balance);
    }

    function getDonation(address donator) external view returns(uint256){
        return donations[donator];
    }


}