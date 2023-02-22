#!/bin/sh

export ACCOUNT_ADDRESS=$1
export CONSTRUCTOR_ARGS=$2

# Compile contracts
echo "Compiling contracts"
CONTRACTS=$(make build)

# Use sed to extract the class hash from the line
ERC721_HASH=$(echo "$CONTRACTS" | grep 'erc721' | cut -d':' -f2 | sed 's/ //g')

# Declare erc721 contract
echo "Declaring erc721 contract"
make declare contract=erc721 account_address=$ACCOUNT_ADDRESS

# Deploy erc721 contract
echo "Deploy erc721 contract"
make deploy class_hash=$ERC721_HASH account_address=$ACCOUNT_ADDRESS constructor_args="$CONSTRUCTOR_ARGS"
