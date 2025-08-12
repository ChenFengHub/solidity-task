const { ethers } = require("hardhat");


describe("CrossChainTest", function () { 

    it("核心测试endAuctionWithCrossChain跨链传输", async function () { 
        const [owner, seller] = await ethers.getSigners();
        console.log("Deployer address:", owner.address, "balance:", await ethers.provider.getBalance(owner.address));
        console.log("seller   address:", seller.address, "balance:", await ethers.provider.getBalance(seller.address));
    

    });


});