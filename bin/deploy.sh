#!/bin/sh

source ./.env

array=("$@")

yarn deploy:hub

yarn deploy:spoke ${array[@]}
