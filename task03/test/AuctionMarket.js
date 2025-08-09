const { ethers }  = require("hardhat");
const { expect } = require("chai");

describe("AuctionMarket TEST", function () { 

    it("test auctoinMarket.sol", async () => {
        const [owner, seller, buyer1, buyer2] = await ethers.getSigners();
        console.log("Deployer address:", owner.address, "balance:", await ethers.provider.getBalance(owner.address));
        console.log("seller   address:", seller.address, "balance:", await ethers.provider.getBalance(seller.address));
        console.log("buyer1   address:", buyer1.address, "balance:", await ethers.provider.getBalance(buyer1.address));
        console.log("buyer2   address:", buyer2.address, "balance:", await ethers.provider.getBalance(buyer2.address));

        // 1. 创建NFT 合约
        const NFT = await ethers.getContractFactory("NFTBid");
        const nft = await NFT.connect(seller).deploy();
        await nft.waitForDeployment();
        const nftAddress = await nft.getAddress();
        const tx = await nft.mintNFT(seller.address, "http://bafybeihivnzqlsfy3nhjchv3auw4raba5xyr2j3skclhtiwnswscdusclq.ipfs.localhost:8080/");
        // const receipt = await tx.wait();
        // // 查找自定义事件
        // const mintedEvent = receipt.events?.find(e => e.event === "Minted");
        const tokenId = 1; // mintedEvent.args.tokenId;
        // console.log("Token ID from Minted event:", tokenId);
        console.log("NFT address:", nftAddress, "tokenId:", tokenId);
        console.log("NFT owner:", await nft.ownerOf(tokenId));

        // 2. 创建AuctionMarket
        const AuctionMarket = await ethers.getContractFactory("AuctionMarket");
        const auctionMarket = await AuctionMarket.connect(owner).deploy();
        await auctionMarket.waitForDeployment();
        const auctionMarketAddress = await auctionMarket.getAddress();
        console.log("AuctionMarket deployed to:", auctionMarketAddress);

        // 3. 创建Auction
        await auctionMarket.createAuctoin(
            seller.address,
            10000,
            nftAddress,
            tokenId,
            0,
            ethers.ZeroAddress//"0x0000000000000000000000000000000000000000"//ethers.ZeroAddress
        );
         // 给代理授权，否则会报错。批量授权给owner，底层调用：IERC721(nftContract).transferFrom(seller, address(this), tokenId);seller即授权的signer
	    // 获取创建的 Auction 合约地址
        const auctionAddress = await auctionMarket.curAuction();
        console.log("Auction address:", auctionAddress);
        await nft.connect(seller).setApprovalForAll(auctionAddress, true);

        // 4. 竞拍
        await auctionMarket.connect(buyer1).partInAuction(
            buyer1.address,
            { value: ethers.parseEther("2") }
        );
        await auctionMarket.connect(buyer2).partInAuction(
            buyer2.address,
            { value: ethers.parseEther("3") }
        );

        // 5. 结束竞拍
        await auctionMarket.endAuction();
        console.log("Deployer address:", owner.address, "balance:", parseFloat(ethers.formatEther(await ethers.provider.getBalance(owner.address))).toFixed(4));
        console.log("seller   address:", seller.address, "balance:", parseFloat(ethers.formatEther(await ethers.provider.getBalance(seller.address))).toFixed(4));
        console.log("buyer1   address:", buyer1.address, "balance:", parseFloat(ethers.formatEther(await ethers.provider.getBalance(buyer1.address))).toFixed(4));
        console.log("buyer2   address:", buyer2.address, "balance:", parseFloat(ethers.formatEther(await ethers.provider.getBalance(buyer2.address))).toFixed(4));
        console.log("nft owner:", await nft.ownerOf(tokenId));
    });

});
