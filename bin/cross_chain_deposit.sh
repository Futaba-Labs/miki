#!/bin/sh

source ./.env

dstChainId=$1
amount=$2

forge script script/SendTransaction.s.sol -s "crossChainETHComposableBridge(uint256, address, uint256, string)" $dstChainId 0x0000000000000000000000000000000000000000 $amount "aave" --rpc-url arbitrum_sepolia --broadcast --verify -vvvv --via-ir --ffi --private-key $PRIVATE_KEY

