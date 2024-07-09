#!/bin/sh

source ./.env

IRIS_URL=https://iris-api-sandbox.circle.com/v1/attestations

# Get the message from the command line argument
if [ $# -eq 0 ]; then
    echo "Error: Message is required as an argument."
    echo "Usage: $0 <message_hash_byte>"
    exit 1
fi

MESSAGE="$1"

# Calculate the keccak256 hash of the message bytes
MESSAGE_HASH=$(cast keccak "$MESSAGE")
echo "Message hash: $MESSAGE_HASH"

# Animation function
animate_pending() {
    local chars=(".   " "..  " "... " "    ")
    printf "\rPending%s (%d seconds)" "${chars[$1]}" $(($(date +%s) - start_time))
}

# Status check loop
counter=0
start_time=$(date +%s)
while true; do
    response=$(curl -s "$IRIS_URL/$MESSAGE_HASH")
    
    if echo "$response" | grep -q "error"; then
        echo "Error: Message hash not found"
    elif echo "$response" | grep -q "pending_confirmations"; then
        animate_pending $((counter % 4))
    elif echo "$response" | grep -q '"status":"complete"'; then
        end_time=$(date +%s)
        elapsed_time=$((end_time - start_time))
        echo "\nCompleted in $elapsed_time seconds:"
        echo "$response" | jq .
        break
    fi
    
    sleep 5
    counter=$((counter + 1))
done
