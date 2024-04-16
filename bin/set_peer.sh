#!/bin/sh

source ./.env

forge script script/adapters/SetPeer.s.sol -s "setLzAdapterPeer()" --rpc-url arbitrum_sepolia --broadcast --verify -vvvv --via-ir --ffi --private-key ${PRIVATE_KEY}

for item in "${array[@]}"
do
  echo Chain: ${item}
  forge script script/adapters/SetPeer.s.sol -s "setLzAdapterPeer()" --rpc-url $item --broadcast --verify -vvvv --via-ir --ffi --private-key ${PRIVATE_KEY}
done

