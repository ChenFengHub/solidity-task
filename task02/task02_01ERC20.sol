// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 作业 1：ERC20 代币
// 任务：参考 openzeppelin-contracts/contracts/token/ERC20/IERC20.sol实现一个简单的 ERC20 代币合约。要求：
// 合约包含以下标准 ERC20 功能：
    // balanceOf：查询账户余额。
    // transfer：转账。
    // approve 和 transferFrom：授权和代扣转账。
    // 使用 event 记录转账和授权操作。
    // 提供 mint 函数，允许合约所有者增发代币。
// 提示：
// 使用 mapping 存储账户余额和授权信息。
// 使用 event 定义 Transfer 和 Approval 事件。
// 部署到sepolia 测试网，导入到自己的钱包

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken {
    // 代币的转账、合约授权、代扣转账、增发代币都是涉及代币比如ERC20，而和ether没有必然联系
    // 合约所有者
    address public owner;

    mapping(address => uint256) private balances; // 所有用户的代币和等于 totalSu
    mapping(address => mapping(address => uint256)) private allowances;
    uint256 public totalSupply = 0;

    event ApproveEvent(address indexed owner, address indexed spender, uint256 value);
    event TransferFromEvent(address indexed owner, address indexed spender, address indexed to, uint256 value);
    event MintEvent(address from, address indexed ctlAdress, address indexed to, uint256 value);

    constructor() {
        owner = msg.sender;
    }

    // 查询账户余额
    function balanceOf(address account) external view  returns (uint256) {
        return balances[account];
    }
    // 转账
    function transfer(address to, uint256 value) external returns (bool) {
        require(balances[msg.sender] >= value, "ERC20: transfer amount exceeds balance" );
        require(to != address(0), "ERC20: transfer to the zero address");
        balances[msg.sender] -= value;
        balances[to] += value;
        // payable(to).transfer(value);
        return true;
    }
    // 一个合约授权（msg.sender）另一个合约（spender）可以一定额度，另一个合约可以通过这个授权抵扣一定额度
    function approve(address spender, uint256 value) external returns (bool) {
        require(spender != address(0), "ERC20: approve to the zero address");
        require(value <= balances[msg.sender], "ERC20: approve amount exceeds balance");
        allowances[msg.sender][spender] = value;
        emit ApproveEvent(msg.sender, spender, value);
        return true;
    }
    // 代扣转账
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(allowances[from][msg.sender] >= value, "ERC20: transfer amount exceeds allowance");
        require(balances[from] >= value, "ERC20: transfer amount exceeds balance");
        require(to != address(0), "ERC20: transfer to the zero address");
        allowances[from][msg.sender] -= value;
        balances[from] -= value;
        balances[to] += value;
        // payable(to).transfer(value);
        emit TransferFromEvent(from, msg.sender, to, value);
        return true;
    }
    // 合约所有者增发代币（增发就是凭空新增所以不用扣减源头，比如银行发行更多货币）
    function mint(address to, uint256 value) external returns (bool) {
        require(msg.sender == owner, "ERC20: mint only owner");
        require(to != address(0), "ERC20: mint to the zero address");
        totalSupply += value;
        balances[to] += value;
        emit MintEvent(address(0), msg.sender, to, value);
        return true;
    }
}