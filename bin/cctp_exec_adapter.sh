#!/bin/sh

source ./.env

forge script script/adapters/CCTPAdapter.s.sol -s 'execCrossChainTransferAsset()' --rpc-url arbitrum_sepolia --broadcast --verify -vvvv --via-ir --ffi --private-key $PRIVATE_KEY
