#!/bin/bash
# spin up the substrate node
docker compose up substrate-node -d
echo "Waiting for the substrate node to start up..."
sleep 10

# deploy contract and extract its address
{ CONTRACT_ADDRESS=$(cd ./protocol && yarn deploy | tee /dev/fd/3 | grep 'contract address:' | awk -F ':  ' '{print $2}'); } 3>&1
export CONTRACT_ADDRESS=$CONTRACT_ADDRESS

# generate mnemonic for the provider
IFS=$'
'
{ PROVIDER_KEYRING=($(cd ./provider && yarn mnemonic | tee /dev/fd/3 | grep ':' | awk -F ': ' '{print $2}' )); } 3>&1

export PROVIDER_ADDRESS=${PROVIDER_KEYRING[0]}
export PROVIDER_MNEMONIC=${PROVIDER_KEYRING[1]}

docker compose up mongodb -d
docker compose up provider-api -d

echo "Dev env up! You can now interact with the provider-api."
CONTAINER_NAME=$(docker ps -q -f name=provider-api)
docker exec -it $CONTAINER_NAME zsh