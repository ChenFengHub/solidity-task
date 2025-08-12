## 测试流程

* 合约文件介绍
    * 基本的竞拍合约：Auction.sol
    * Uniswap V2工厂合约：AuctionFactory.sol
    * 竞拍市场合约（管理入口，同时只能有一场合约进行中）：AuctionMarket.sol
    * 跨链消息接收处理合约：AuctionNFTReceiver.sol

* 基本功能测试：NFT合约创建、拍卖合约的创建（Uniswap V2）/竞拍/结束竞拍/比对最终的结果
    * 测试脚本：test/AuctionMarketBasic.js
    * 本地测试即可：进入task03目录，执行：npx hardhat test test/AuctionMarketBasic.js
* 跨链功能测试
    * 先部署跨链合约节点，使用sepolia测试网，部署脚本：script/AuctionNFTReceiverDeploy.js，执行指令： npx hardhat run script/AuctionNFTReceiverDeploy.js --network sepolia
    * 执行测试脚本，发起跨链请求，使用hoodi测试脚本：test/CrossChainTest.js，执行指令：