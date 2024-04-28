#!/bin/sh

source ./.env

dstChainId=$1
recipient=$2


forge script script/SendTransaction.s.sol -s "crossChainMint(uint256, address)" $dstChainId $recipient --rpc-url arbitrum_sepolia --broadcast --verify -vvvv --via-ir --ffi --private-key ${PRIVATE_KEY}

