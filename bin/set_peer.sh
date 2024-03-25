#!/bin/sh

name=$1

echo Funtion: ${name}

shift
array=("$@")

for item in "${array[@]}"
do
  echo Chain: ${item}
  forge script script/adapters/SetPeer.s.sol $1 -s $name --rpc-url $item --broadcast --verify -vvvv --via-ir --ffi
done

