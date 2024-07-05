#!/bin/sh

source ./.env

forge script script/adapters/CCTPReceiver.s.sol -s 'deploy()' --rpc-url base_sepolia --broadcast --verify -vvvv --via-ir --ffi --private-key $PRIVATE_KEY
