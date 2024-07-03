import * as dotenv from 'dotenv';
dotenv.config();

import { utils, Wallet } from "zksync-ethers";
import * as ethers from "ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployer } from "@matterlabs/hardhat-zksync";

// An example of a deploy script that will deploy and call a simple contract.
export default async function (hre: HardhatRuntimeEnvironment) {
  console.log(`Running deploy script`);

  // Initialize the wallet.
  const privateKey = process.env.PRIVATE_KEY;
  if (!privateKey) {
    throw new Error("No private key found");
  }

  const wallet = new Wallet(privateKey);
  const mikiRouter = "0xa0F2e702D40996ceD792213D9e96741603bDee46"

  // Create deployer object and load the artifact of the contract we want to deploy.
  const deployer = new Deployer(hre, wallet);
  // Load contract
  const mikiReceiverArtifact = await deployer.loadArtifact("MikiReceiver");
  const mikiRouterReceiverArtifact = await deployer.loadArtifact("MikiRouterReceiver");

  // deploy miki receiver
  console.log("Deploying miki receiver...");
  console.log("args: ", [wallet.address]);
  const mikiReceiver = await deployer.deploy(mikiReceiverArtifact, [wallet.address]);
  const mikiReceiverAddress = await mikiReceiver.getAddress();

  // Show the contract info
  console.log(`${mikiReceiverArtifact.contractName} was deployed to ${mikiReceiverAddress}`);

  // deploy miki router receiver
  console.log("Deploying miki router receiver...");
  console.log("args: ", [mikiRouter, mikiReceiverAddress, wallet.address]);
  const mikiRouterReceiver = await deployer.deploy(mikiRouterReceiverArtifact, [mikiRouter, mikiReceiverAddress, wallet.address]);

  const mikiRouterReceiverAddress = await mikiRouterReceiver.getAddress();
  console.log(`${mikiRouterReceiverArtifact.contractName} was deployed to ${mikiRouterReceiverAddress}`);

  // set adapters
  const txn = await mikiReceiver.setAdapters([mikiRouterReceiverAddress]);
  await txn.wait();

  console.log(`Adapters set for ${mikiReceiverAddress}`);

}
