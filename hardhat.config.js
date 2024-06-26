require ("@nomiclabs/hardhat-ethers");
require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-etherscan");

const PRIVATE_KEY = "b598f2ce8638aa904dc3b9bec061591b8b4223633fb7ce7b109c97cec6827ce7";

module.exports = {
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },

  },

  networks: {
    // bsctestnet: {
    //   url: " https://data-seed-prebsc-1-s1.binance.org:8545/ ",
    //   chainId:97,
    //   accounts: [PRIVATE_KEY],
    // }

    MumbaiTestnet: {
      url: "https://rpc-mumbai.maticvigil.com/",
      chainId:80001,
      accounts: [PRIVATE_KEY],
    }
  },
  
  // bscscan: {
  //   // Your API key for Etherscan
  //   // Obtain one at  https://etherscan.io/ 
  //   // apiKey: ""
  //   apiKey :{ 
  //     bscTestnet :""
  //   } 
  // }
  etherscan: {
    apiKey: "H69FUGKIPB4KV5MKGPRHJ2U9Y1KKIQ5GG2"
  }
};