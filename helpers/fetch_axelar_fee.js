const {
  AxelarQueryAPI,
  CHAINS,
  Environment,
  GasToken
} = require('@axelar-network/axelarjs-sdk');

const ethers = require('ethers');


async function main() {
  const sdk = new AxelarQueryAPI({
    environment: Environment.TESTNET,
  });

  const fee = await sdk.estimateGasFee(
    "arbitrum-sepolia",
    "optimism-sepolia",
    GasToken.ETH,
    500000
  );

  console.log(ethers.utils.defaultAbiCoder.encode(["uint256"], [parseFloat(fee)]));
}

main();
