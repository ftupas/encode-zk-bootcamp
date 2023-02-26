#!/bin/sh

export ACCOUNT_ADDRESS=$1

# Compile contracts
echo "Compiling contracts"
CONTRACTS=$(make build)

# Use sed to extract the class hash from the line
STORAGE_HASH=$(echo "$CONTRACTS" | grep 'storage' | cut -d':' -f2 | sed 's/ //g')

# Declare erc721 contract
echo "Declaring storage contract"
make declare contract=storage account_address=$ACCOUNT_ADDRESS

# Deploy erc721 contract
echo "Deploy storage contract"
make deploy class_hash=$STORAGE_HASH account_address=$ACCOUNT_ADDRESS
