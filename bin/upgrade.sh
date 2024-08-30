#!/bin/sh

source ./.env

forge script script/Deploy.s.sol -s "upgrade()" --rpc-url arbitrum_sepolia --broadcast --verify -vvvv --via-ir --ffi --private-key ${PRIVATE_KEY}
