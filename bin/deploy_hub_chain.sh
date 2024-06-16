#!/bin/sh

source ./.env

echo "Deploying hub chain..."

forge script script/Deploy.s.sol --rpc-url arbitrum_sepolia --broadcast --verify -vvvv --via-ir --ffi --private-key ${PRIVATE_KEY}
