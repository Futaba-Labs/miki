#!/bin/sh

source ./.env

echo Chain: arbitrum_sepolia
forge script script/Deploy.s.sol -s "deployEthAdapter()" --rpc-url arbitrum_sepolia --broadcast --verify -vvvv --via-ir --ffi --private-key ${PRIVATE_KEY}
