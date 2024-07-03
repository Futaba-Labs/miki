#!/bin/sh

source ./.env

if [ $# -ne 2 ]; then
    echo "Error: Message and attestation are required as arguments."
    echo "Usage: $0 <message> <attestation>"
    exit 1
fi

echo $2

forge script script/adapters/CCTPReceiver.s.sol --rpc-url base_sepolia --broadcast --verify -vvvv --via-ir --ffi --private-key $PRIVATE_KEY --sig "run(bytes,bytes)"  $1 $2
