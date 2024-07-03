#!/bin/sh

source ./.env

array=("$@")

for item in "${array[@]}"
do
    echo Deploy MikiRouterReceiver on ${item}
    if [ ${item} == "zksync_sepolia" ]; then
        yarn hardhat deploy-zksync --script deployZksync.ts --network zkSyncTestnet
    else
        forge script script/Deploy.s.sol -s "deployMikiRouterReceiver()" --rpc-url ${item} --broadcast --verify -vvvv --via-ir --ffi --private-key ${PRIVATE_KEY}
    fi
done
