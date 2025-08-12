const { ethers } = require("hardhat");
const {deployments, upgrades} = require("hardhat");
// filestring缩写
const fs = require("fs"); 
const path = require("path");
module.exports = async ({getNamedAccounts, deployments}) => {
    const {save} = deployments;
    // 从hardhat.confg.js中获取部署的用户地址
    const {deployer} = await getNamedAccounts();
    console.log("部署：用户地址：", deployer);
    const auctionMarket = await ethers.getContractFactory("AuctionMarket");
    // 通过（普通）代理部署合约
    const auctionMarketProxy = await upgrades.deployProxy(
        auctionMarket, 
        [], 
        {initializer: "initialize"} // 指定合约执行的初始化方法，名字要统一
    );
    await auctionMarketProxy.waitForDeployment();
    const proxyAddress = await auctionMarketProxy.getAddress();
    const implAddress = await upgrades.erc1967.getImplementationAddress(proxyAddress);
    console.log("部署：代理合约地址：", proxyAddress);
    console.log("部署：目标合约地址（实现合约地址）：", implAddress);

    const storePath = path.resolve(__dirname, "./.cache/proxyAuctionMarket.json");
    
    fs.writeFileSync(
        storePath,
        JSON.stringify({
            proxyAddress,
            implAddress,
            abi: auctionMarket.interface.format("json"),
        })
    );
    await save("AuctionMarketProxy", {
        abi: auctionMarket.interface.format("json"),
        address: proxyAddress,
        // args: [],
        // log: true,
    });
};
module.exports.tags = ["deployProxyAuctionMarket"];
