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
    "mantle-sepolia",
    GasToken.ETH,
    500000000
  );

  console.log(ethers.utils.defaultAbiCoder.encode(["uint256"], [parseFloat(fee)]));
}

main();
