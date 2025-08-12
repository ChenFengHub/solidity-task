const { ethers } = require("hardhat");


describe("CrossChainTest", function () {
    // 当前部署网络的路由地址（hoodi ccip路由器地址）
    const routerAddress = "0x114A20A10b43D4115e5aeef7345a1A71d2a60C57"; 
    // 部署的AuctionNFTReceiver合约地址
    const receiverAddress = "0x3e3C829D367233DBbc316cd4958eb4f0485B2aF6";

    it("核心测试endAuctionWithCrossChain跨链传输", async function () { 
        // 增加超时时间到180秒=》3分钟=》延长到30分钟
        this.timeout(180000 * 10);

        const [owner, seller, buyer] = await ethers.getSigners();
        console.log("owner  address:", owner.address, "balance:", parseFloat(ethers.formatEther(await ethers.provider.getBalance(owner.address))).toFixed(4));
        console.log("seller address:", seller.address, "balance:", parseFloat(ethers.formatEther(await ethers.provider.getBalance(seller.address))).toFixed(4));
        console.log("buyer  address:", buyer.address, "balance:", parseFloat(ethers.formatEther(await ethers.provider.getBalance(buyer.address))).toFixed(4));

        const NFT = await ethers.getContractFactory("NFTBid");
        const nft = await NFT.deploy();
        await nft.waitForDeployment();
        const nftAddress = await nft.getAddress();

        const tokenId = 1;
        await nft.mintNFT(seller.address, "http://bafybeihivnzqlsfy3nhjchv3auw4raba5xyr2j3skclhtiwnswscdusclq.ipfs.localhost:8080/");

        const AuctoinFacotry = await ethers.getContractFactory("AuctionFactory");
        const auctionFactory = await AuctoinFacotry.deploy();
        await auctionFactory.waitForDeployment();
        const auctionFactoryAddress = await auctionFactory.getAddress();
        console.log("AuctionFactory deployed to:", auctionFactoryAddress);

        const AuctionMarket = await ethers.getContractFactory("AuctionMarket");
        const auctionMarket = await AuctionMarket.deploy();
        await auctionMarket.waitForDeployment();
        await auctionMarket.setAuctionFactory(auctionFactoryAddress);

        let creationTx = await auctionMarket.createAuctoin(
            seller.address,
            1000000,
            nftAddress,
            tokenId,
            0,
            "0x0000000000000000000000000000000000000000"// ethers.ZeroAddress
        );
        console.log("Auction creation tx hash:", creationTx.hash);
        // 增加详细的交易回执信息。确保合约中创建合约成功后，才往下执行
        const receipt = await creationTx.wait();
        console.log("Auction creation successful:");
        console.log("  Gas used:", receipt.gasUsed.toString());
        console.log("  Block number:", receipt.blockNumber);
        console.log("  Transaction status:", receipt.status);

        const auctionAddress = await auctionMarket.curAuction();
        console.log("auctionAddress:", auctionAddress);
        
        let appTx = await nft.connect(seller).setApprovalForAll(auctionAddress, true);
        appTx.wait();

        let partInTx = await auctionMarket.connect(buyer).partInAuction(
            buyer.address,
            { value: ethers.parseEther("0.05") }
        );
        partInTx.wait();

        // 设置路由地址，设置跨链接收合约的部署地址
        let routerAddrTx = await auctionMarket.setRouter(routerAddress);
        await routerAddrTx.wait();
        let receiverAddrTx = await auctionMarket.setReceiverAddress(receiverAddress);
        await receiverAddrTx.wait();
        console.log("receiverAddress:", await auctionMarket.getReceiverAddress());

        // 测试跨链
        console.log("跨链前的NFT owner:", await nft.ownerOf(tokenId));
        // 为拍卖合约提供足够的 ETH 用于支付跨链手续费
        console.log("Funding auction contract...");
        const fundTx = await owner.sendTransaction({
            to: auctionAddress,
            value: ethers.parseEther("0.02") // 发送0.01~0.02 ETH用于支付手续费
        });
        await fundTx.wait();
        console.log("begin cross chain...");
        let crossTx = await auctionMarket.endAuctionWithCrossChain();
        await crossTx.wait();
        console.log("跨链后的NFT owner:", await nft.ownerOf(tokenId));
    });


});