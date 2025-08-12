const { deploy } = require("@openzeppelin/hardhat-upgrades/dist/utils");
const { ethers, upgrades }  = require("hardhat");
const { expect } = require("chai");
const {fs} = require("fs");
const {path} = require("path");
describe("Starting", () => {
    it("test deploy+upgrade", async () => {
        const [owner, seller, buyer] = await ethers.getSigners();

        // 1. 部署业务合约
        // fixture中指定的名字为 01_deploy_nft_auction.js中module.exports.tags的名字
        await deployments.fixture(["deployProxyAuctionMarket"]);
        // 名字使用01_deploy_nft_auction.js中save中保存的名字
        const auctionMarketProxy = await deployments.get("AuctionMarketProxy");
        // 2. 调用createAuction方法创建拍卖
        // 使用已有的合约地址，创建合约
        const auctionMarket = await ethers.getContractAt(
            "AuctionMarket", 
            auctionMarketProxy.address
        );

        // 获取auctionFactory是否存在，不存在则创建
        const auctionFactory = await auctionMarket.auctionFactory();
        if (auctionFactory === ethers.ZeroAddress) {
            const AuctionFactory = await ethers.getContractFactory("AuctionFactory");
            const auctionFactory = await AuctionFactory.deploy();
            await auctionFactory.waitForDeployment();
            let auctionFactoryAddress = await auctionFactory.getAddress();
            console.log("新建的AuctionFactory合约地址：", auctionFactoryAddress);
            let setFactory = await auctionMarket.setAuctionFactory(auctionFactoryAddress);
            await setFactory.wait();
        }

        const tokenId = 1;
        const existAuction = await auctionMarket.curAuction();
        console.log("existAuction：", existAuction);
        if (existAuction == ethers.ZeroAddress) {
            console.log("拍卖不存在，开始新建...");
            const NFT = await ethers.getContractFactory("NFTBid");
            const nft = await NFT.deploy();
            await nft.waitForDeployment();
            const nftAddress = await nft.getAddress();
            console.log("新建的NFT address:", nftAddress);
            await nft.mintNFT(seller.address, "http://bafybeihivnzqlsfy3nhjchv3auw4raba5xyr2j3skclhtiwnswscdusclq.ipfs.localhost:8080/");

            let createTx = await auctionMarket.createAuctoin(
                seller.address,
                1000000,
                nftAddress,
                tokenId,
                0,
                "0x0000000000000000000000000000000000000000"// ethers.ZeroAddress
            );
            await createTx.wait();
            console.log("拍卖不存在，新建完成");
        } else {
            let existNftContract = await existAuction.nftContract();
            if (existNftContract == ethers.ZeroAddress) {
                console.log("拍卖中 NFT 不存在，开始更新...");
                const NFT = await ethers.getContractFactory("NFTBid");
                const nft = await NFT.deploy();
                await nft.waitForDeployment();
                const nftAddress = await nft.getAddress();
                console.log("新建的NFT address:", nftAddress);
                await nft.mintNFT(seller.address, "http://bafybeihivnzqlsfy3nhjchv3auw4raba5xyr2j3skclhtiwnswscdusclq.ipfs.localhost:8080/");
                await existAuction.setNftContract(nftAddress);
                console.log("拍卖中 NFT 不存在，更新完成");
            }
        }

        const auction = await auctionMarket.curAuction();
        console.log("创建拍卖成功：", auction);
        const implAddress = await upgrades.erc1967.getImplementationAddress(
            auctionMarketProxy.address
        );

        // 3. 升级合约
        await deployments.fixture(["upgradeProxyAuctionMarket"]);
        const auctionMarketProxyV2 = await deployments.get("AuctionMarketProxyV2");
        const auctionMarket2 = await ethers.getContractAt(
            "AuctionMarketV2", 
            auctionMarketProxyV2.address
        );
        const auction2 = await auctionMarket2.curAuction();
        console.log("升级拍卖成功：", auction2);
        const implAddress2 = await upgrades.erc1967.getImplementationAddress(
            auctionMarketProxyV2.address
        );

        // 4. 对比更新后的合约是否地址是否不同
        expect(auction).equal(auction2, "升级后的合约地址和升级前的合约地址不一致");
        console.log(`implAddress2: ${implAddress2}, implAddress: ${implAddress}`);
        expect(implAddress2).to.not.equal(implAddress, "新建和更新的拍卖市场合约地址相等(更新前后地址应该不同)");
    });
});
