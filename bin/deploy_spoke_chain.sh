#!/bin/sh

source ./.env

array=("$@")

echo "Deploying spoke chains..."

for item in "${array[@]}"
do
  echo Chain: ${item}
  if [ "${item}" = "mantle_sepolia" ]; then
    forge script script/Deploy.s.sol --rpc-url $item --broadcast --verify -vvvv --via-ir --ffi --private-key ${PRIVATE_KEY} --legacy -g 4000000
  else
    forge script script/Deploy.s.sol --rpc-url $item --broadcast --verify -vvvv --via-ir --ffi --private-key ${PRIVATE_KEY}
  fi
done

echo Setting LayerZero/Axelar Peer...

echo Chain: arbitrum_sepolia

forge script script/adapters/SetPeer.s.sol -s "setLzAdapterPeer()" --rpc-url arbitrum_sepolia --broadcast --verify -vvvv --via-ir --ffi --private-key ${PRIVATE_KEY}

for item in "${array[@]}"
do
  echo Chain: ${item}

  if [ "${item}" = "mantle_sepolia" ]; then
    forge script script/adapters/SetAxelarReceiver.s.sol --rpc-url arbitrum_sepolia --broadcast --verify -vvvv --via-ir --ffi --private-key ${PRIVATE_KEY}
  else
    forge script script/adapters/SetPeer.s.sol -s "setLzAdapterPeer()" --rpc-url $item --broadcast --verify -vvvv --via-ir --ffi --private-key ${PRIVATE_KEY}
  fi
done

for item in "${array[@]}"
do
  echo Chain: ${item}
  forge script script/Deploy.s.sol -s "setBridgeAdapter(string, address)" $item 0x0000000000000000000000000000000000000000 --rpc-url arbitrum_sepolia --broadcast --verify -vvvv --via-ir --ffi --private-key ${PRIVATE_KEY}
done

echo Setting LayerZero eids...

forge script script/Deploy.s.sol -s "setEids()" --rpc-url arbitrum_sepolia --broadcast --verify -vvvv --via-ir --ffi --private-key ${PRIVATE_KEY}
