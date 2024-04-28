#!/bin/sh

source ./.env

amount=$1

forge script script/SendTransaction.s.sol -s "depositETH(uint256)" $amount --rpc-url arbitrum_sepolia --broadcast --verify -vvvv --via-ir --ffi --private-key ${PRIVATE_KEY}