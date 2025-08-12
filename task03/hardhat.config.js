require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();
require("hardhat-deploy");
require("@openzeppelin/hardhat-upgrades");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
  namedAccounts: {
    deployer: 0,
    user1: 1,
    user2: 2,
  },
  networks: {
    sepolia: {
      url: `https://sepolia.infura.io/v3/${process.env.INFURA_API_KEY}`,  // 从sepolia中随便选个可用的地址，从https://developer.metamask.io/中获取
      accounts: [process.env.PRIVATE_KEY]    // 账户私钥，正常是严禁保存泄露的
    },
    hoodi: {
      url: `https://hoodi.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts: [
        process.env.PRIVATE_KEY,
        process.env.PRIVATE_KEY_2,
        process.env.PRIVATE_KEY_3
      ]
    },
    fuji: {
      url: `https://api.avax-test.network/ext/bc/C/rpc`,
      accounts: [process.env.PRIVATE_KEY]
    },
    polygon: {
      url: `https://polygon-mumbai.infura.io/v3/b6a39ba8bb49482fbef08826773901cc`,
      accounts: [process.env.PRIVATE_KEY]
    },
    optimismSepolia: {
      url: "https://sepolia.optimism.io",
      accounts: [process.env.PRIVATE_KEY]
    },
    bsctestnet: {
      url: "https://data-seed-prebsc-1-s1.bnbchain.org:8545",
      accounts: [process.env.PRIVATE_KEY]
    }
  },

};
