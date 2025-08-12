const { ethers }  = require("hardhat");
const { expect } = require("chai");

describe("AuctionMarket Basic TEST(Not include auto upgrade)", function () { 

    it("测试单链相关功能", async () => {
        const [owner, seller, buyer1, buyer2, seller2] = await ethers.getSigners();
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
        const AuctoinFacotry = await ethers.getContractFactory("AuctionFactory");
        const auctionFactory = await AuctoinFacotry.deploy();
        await auctionFactory.waitForDeployment();
        const auctionFactoryAddress = await auctionFactory.getAddress();
        console.log("AuctionFactory deployed to:", auctionFactoryAddress);
       
        const AuctionMarket = await ethers.getContractFactory("AuctionMarket");
        const auctionMarket = await AuctionMarket.connect(owner).deploy();
        await auctionMarket.waitForDeployment();
        const auctionMarketAddress = await auctionMarket.getAddress();

        let setFactoryTx = await auctionMarket.setAuctionFactory(auctionFactoryAddress);
        await setFactoryTx.wait();
        
        console.log("AuctionMarket deployed to:", auctionMarketAddress);

        // 3. 创建Auction
        await auctionMarket.createAuctoin(
            seller.address,
            10000,
            nftAddress,
            tokenId,
            0,
            "0x0000000000000000000000000000000000000000" //ethers.ZeroAddress
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
        console.log("手续费-owner      fee:", await auctionMarket.getFeeAmount());
        console.log("手续费-sellerProceeds:", await auctionMarket.getSellerProceeds());
        console.log("deployer address:", owner.address, "balance:", parseFloat(ethers.formatEther(await ethers.provider.getBalance(owner.address))).toFixed(4));
        console.log("seller   address:", seller.address, "balance:", parseFloat(ethers.formatEther(await ethers.provider.getBalance(seller.address))).toFixed(4));
        console.log("buyer1   address:", buyer1.address, "balance:", parseFloat(ethers.formatEther(await ethers.provider.getBalance(buyer1.address))).toFixed(4));
        console.log("buyer2   address:", buyer2.address, "balance:", parseFloat(ethers.formatEther(await ethers.provider.getBalance(buyer2.address))).toFixed(4));
        console.log("nft owner:", await nft.ownerOf(tokenId));

        // 6. 开始第二轮竞拍(一个采用ERC20，一个采用ether) =====================
        // 铸币
        const MyToken = await ethers.getContractFactory("MyToken");
        const myToken = await MyToken.connect(owner).deploy("MyToken", "MySympol");
        await myToken.waitForDeployment();
        await myToken.mint(buyer1.address, 100000);
        await myToken.mint(buyer2.address, 100000);
        
        const myTokenAddress = await myToken.getAddress();
        console.log("seller2 erc20 balance:", await myToken.balanceOf(seller2.address));
        console.log("buyer1  erc20 balance:", await myToken.balanceOf(buyer1.address));
        console.log("buyer2  erc20 balance:", await myToken.balanceOf(buyer2.address));


        const tokenId2 = 2
        await nft.mintNFT(seller2.address, "http://bafybeihivnzqlsfy3nhjchv3auw4raba5xyr2j3skclhtiwnswscdusclq.ipfs.localhost:8080/");
        await auctionMarket.createAuctoin(
            seller2.address,
            10000,
            nftAddress,
            tokenId2,
            0,
            "0x0000000000000000000000000000000000000000"// ethers.ZeroAddress
        );
        const secAuctionAddress = await auctionMarket.curAuction();
        await nft.connect(seller2).setApprovalForAll(secAuctionAddress, true);
        // 授权5w的代币，这样转账时才可以成功
        await myToken.connect(buyer1).approve(secAuctionAddress, 50000);
        await auctionMarket.connect(buyer2).partInAuction(
            buyer2.address,
            { value: ethers.parseEther("8") }
        );
        await auctionMarket.connect(buyer1).partInAuctionWithERC20(
            buyer1.address,
            24001,
            myTokenAddress
        );
        
        await auctionMarket.endAuction();
        
        console.log("第二轮：手续费-owner      fee:", await auctionMarket.getFeeAmount());
        console.log("第二轮：手续费-sellerProceeds:", await auctionMarket.getSellerProceeds());
        console.log("第二轮：Deployer address:", owner.address, "balance:", parseFloat(ethers.formatEther(await ethers.provider.getBalance(owner.address))).toFixed(4));
        console.log("第二轮：seller2   address:", seller2.address, "balance:", parseFloat(ethers.formatEther(await ethers.provider.getBalance(seller2.address))).toFixed(4));
        console.log("第二轮：buyer1   address:", buyer1.address, "balance:", parseFloat(ethers.formatEther(await ethers.provider.getBalance(buyer1.address))).toFixed(4));
        console.log("第二轮：buyer2   address:", buyer2.address, "balance:", parseFloat(ethers.formatEther(await ethers.provider.getBalance(buyer2.address))).toFixed(4));
        console.log("第二轮：nft owner:", await nft.ownerOf(tokenId2));
        console.log("第二轮：seller2 erc20 balance:", await myToken.balanceOf(seller2.address));
        console.log("第二轮：buyer1  erc20 balance:", await myToken.balanceOf(buyer1.address));
        console.log("第二轮：buyer2  erc20 balance:", await myToken.balanceOf(buyer2.address));
    });



});
