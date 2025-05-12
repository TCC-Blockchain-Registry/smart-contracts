require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.19",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
  },
  networks: {
    fabric: {
      url: "grpcs://localhost:7051",
      chainId: 1337,
      accounts: {
        mnemonic: process.env.MNEMONIC || "test test test test test test test test test test test junk"
      },
      fabric: {
        connectionProfile: "./config/connection-profile.json",
        walletPath: "./wallet",
        identity: "appUser",
        channel: "mychannel",
        chaincode: "title-transfer"
      }
    }
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  mocha: {
    timeout: 40000
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD"
  },
  docgen: {
    path: './docs',
    clear: true,
    runOnCompile: true
    }
};
