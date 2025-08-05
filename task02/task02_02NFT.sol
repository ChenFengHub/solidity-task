// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


// 作业2：在测试网上发行一个图文并茂的 NFT
// 任务目标
    // 1.使用 Solidity 编写一个符合 ERC721 标准的 NFT 合约。
    // 2.将图文数据上传到 IPFS，生成元数据链接。
    // 3.将合约部署到以太坊测试网（如 Goerli 或 Sepolia）。
    // 4.铸造 NFT 并在测试网环境中查看。
// 任务步骤
    // 1.编写 NFT 合约
        // 使用 OpenZeppelin 的 ERC721 库编写一个 NFT 合约。
        // 合约应包含以下功能：
        // 构造函数：设置 NFT 的名称和符号。
        // mintNFT 函数：允许用户铸造 NFT，并关联元数据链接（tokenURI）。
        // 在 Remix IDE 中编译合约。
    // 2.准备图文数据
        // 准备一张图片，并将其上传到 IPFS（可以使用 Pinata 或其他工具）。
            // 安装IPSF:IPFS（InterPlanetary File System：星际文件系统）下载本地客户端地址：https://docs.ipfs.tech/install/ipfs-desktop/#windows；官网：https://ipfs.tech/
            // 创建本地节点：本地初始化IPFS:ipfs init（或者直接使用管理端的：文件→导入功能，进行添加节点）
        // 将 JSON 文件上传到 IPFS，获取元数据链接。
        // JSON文件参考 https://docs.opensea.io/docs/metadata-standards
    // 3.部署合约到测试网
        // 在 Remix IDE 中连接 MetaMask，并确保 MetaMask 连接到 Goerli 或 Sepolia 测试网。
        // 部署 NFT 合约到测试网，并记录合约地址。
    // 4.铸造 NFT
        // 使用 mintNFT 函数铸造 NFT：
        // 在 recipient 字段中输入你的钱包地址。
        // 在 tokenURI 字段中输入元数据的 IPFS 链接。
        // 在 MetaMask 中确认交易。
    // 5.查看 NFT
        // 打开 OpenSea 测试网 或 Etherscan 测试网。
        // 连接你的钱包，查看你铸造的 NFT。

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


contract MyNFT is ERC721 {

    mapping(uint256 tokenId => string tokenURI) tokenURIs; 
       
    constructor() ERC721("MyNFT", "MySymbol") {}

    // 铸造NFT
    function mintNFT(address recipient, uint256 tokenId, string memory tokenURI) external {
        _mint(recipient, tokenId);  // _mint()不能保证令牌先铸造完成，使用安全方法_safeMint来保证
       setTokenURI(tokenId, tokenURI);
    }

    // 根据tokenId获取uri
    function getTokenURI(uint256 tokenId) public view returns (string memory) {
        return tokenURIs[tokenId];
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public {
        require(_ownerOf(tokenId) != address(0), "ERC721: URI set of nonexistent token");
        tokenURIs[tokenId] = _tokenURI;
    }

    // function _exists(uint256 tokenId) internal view returns (bool) {
    //     return bytes(tokenURIs[tokenId]).length > 0;
    // }

}