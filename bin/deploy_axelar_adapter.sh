#!/bin/sh

source ./.env

echo Chain: arbitrum_sepolia
forge script script/Deploy.s.sol -s "deployAxelarAdapter()" --rpc-url arbitrum_sepolia --broadcast --verify -vvvv --via-ir --ffi --private-key ${PRIVATE_KEY}

echo: Set Axelar Receiver
forge script script/adapters/SetAxelarReceiver.s.sol --rpc-url arbitrum_sepolia --broadcast --verify -vvvv --via-ir --ffi --private-key ${PRIVATE_KEY}
