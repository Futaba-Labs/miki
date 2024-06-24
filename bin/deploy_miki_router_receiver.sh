#!/bin/sh

source ./.env

array=("$@")

for item in "${array[@]}"
do
    echo Deploy MikiRouterReceiver on ${item}
    forge script script/Deploy.s.sol -s "deployMikiRouterReceiver()" --rpc-url ${item} --broadcast --verify -vvvv --via-ir --ffi --private-key ${PRIVATE_KEY}
done
