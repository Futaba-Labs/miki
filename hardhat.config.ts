import * as dotenv from 'dotenv';
dotenv.config();

import type { HardhatUserConfig } from "hardhat/config";

import "@matterlabs/hardhat-zksync";
import "@matterlabs/hardhat-zksync-verify";


const accounts =
  process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [];

// dynamically changes endpoints for local tests
const config: HardhatUserConfig = {
  paths: {
    deployPaths: "script", //single deployment directory
    sources: "./src",
  },
  etherscan: {
    apiKey: process.env.API_KEY_ZKSYNC,
  },
  networks: {
    hardhat: {
      zksync: false,
    },
    zkSyncTestnet: {
      url: "https://sepolia.era.zksync.dev",
      ethNetwork: "sepolia", // or a Sepolia RPC endpoint from Infura/Alchemy/Chainstack etc.
      zksync: true,
      accounts: accounts,
      verifyURL: 'https://explorer.sepolia.era.zksync.dev/contract_verification'
    },
  },
  defaultNetwork: "zkSyncTestnet",
  zksolc: {
    version: "latest",
    settings: {},
  },
  solidity: {
    version: "0.8.23",
  }
};


export default config;