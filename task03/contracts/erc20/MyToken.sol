// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20 {

    address public owner;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        owner = msg.sender;
    }   
    
    // 只有合约所有者可以铸造新代币
    function mint(address to, uint256 amount) public {
        require(owner == msg.sender, "Only the owner can mint new tokens");
        _mint(to, amount);
    }

    // 任何人都可以销毁自己的代币
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    // 合约所有者可以销毁任何人的代币（可选）
    function burnFrom(address account, uint256 amount) public {
        require(owner == msg.sender, "Only owner can anyone's tokens");
        _spendAllowance(account, owner, amount);
        _burn(account, amount);
    }

} 