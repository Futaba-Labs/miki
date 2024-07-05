#!/bin/sh

source ./.env

forge script script/appReceivers/EmptyAppReceiver.s.sol -s 'deploy()' --rpc-url base_sepolia --broadcast --verify -vvvv --via-ir --ffi --private-key $PRIVATE_KEY
