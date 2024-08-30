#!/bin/sh

source ./.env

dstChainId=$1
to=$2
amount=$3

forge script script/SendTransaction.s.sol -s "crossChainETHBridge(uint256, address, uint256)" $dstChainId $to $amount --rpc-url arbitrum_sepolia --broadcast --verify -vvvv --via-ir --ffi --private-key $PRIVATE_KEY

