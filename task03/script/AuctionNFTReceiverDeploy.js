const { ethers } = require("hardhat");

// 使用 SEPOLIA 测试网的 CCIP Router (已修正校验和)
const SEPOLIA_CCIP_ROUTER = "0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59";
// 目标链选择器 (Ethereum Sepolia)
const SEPOLIA_CHAIN_SELECTOR = "16015286601757825753";

// hoodi
const HOODI_CCIP_ROUTER = "0x114A20A10b43D4115e5aeef7345a1A71d2a60C57";
const HOODI_CHAIN_SELECTOR = "5224473277236538624";

// 使用 Fuji 测试网的 CCIP Router (已修正校验和)
const FUJI_CCIP_ROUTER = "0xF694E193200268f9a4868e4Aa017A0118C9a8177";
const FUJI_CHAIN_SELECTOR = "14767482510784806043";


// POLYGON
// CCIP ROUTER地址
const POLYGON_CCIP_ROUTER = "0xd44888d9DeB858e4BF4BE2CA3BAb0BBd404FeDED";
// 目标链选择器 (Polygon Mumbai)
const POLYGON_DESTINATION_CHAIN_SELECTOR = "13464554885522680855";

// Optimism Sepolia
const OPTIMISM_SEPOLIA_CCIP_ROUTER = "0x114A20A10b43D4115e5aeef7345a1A71d2a60C57";
// 目标链选择器 (Optimism Sepolia)
const OPTIMISM_SEPOLIA_CHAIN_SELECTOR = "5224473277236538624";

async function main() {
    console.log("Deploying CrossChainNFTReceiver to testnet...");
    
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
    console.log("Account balance:", parseFloat(ethers.formatEther(await ethers.provider.getBalance(deployer.address))).toFixed(4));
    
    // 部署跨链接收器合约
    const AuctionNFTReceiver = await ethers.getContractFactory("AuctionNFTReceiver");
    const auctionNFTReceiver = await AuctionNFTReceiver.deploy(SEPOLIA_CCIP_ROUTER);
    await auctionNFTReceiver.waitForDeployment();
    const receiverAddress = await auctionNFTReceiver.getAddress();
    console.log("AuctionNFTReceiver deployed to:", receiverAddress);
    
    // 验证部署
    console.log("验证路由器地址:", await auctionNFTReceiver.getRouter());
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });