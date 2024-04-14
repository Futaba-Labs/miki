#!/bin/sh

name=$1

echo Funtion: ${name}

shift
array=("$@")

for item in "${array[@]}"
do
  echo Chain: ${item}
  forge script script/adapters/SetPeer.s.sol $1 -s $name --rpc-url $item --broadcast --verify -vvvv --via-ir --ffi --private-key 0xbbe89bcfb5dc97d73a083246c49fd0b6d43156d9b2f1057dd0e8d57bdbe7c9a5
done

