#!/bin/bash

# spin up the substrate node
docker compose up substrate-node -d
echo "Waiting for the substrate node to start up..."
sleep 10

# deploy contract and extract its address
{ CONTRACT_ADDRESS=$(cd ./protocol && yarn && yarn deploy | tee /dev/fd/3 | grep 'contract address:' | awk -F ':  ' '{print $2}'); } 3>&1
export CONTRACT_ADDRESS=$CONTRACT_ADDRESS

# install packages
$(cd provider && yarn);
# generate mnemonic for the provider

IFS=$'
'
{ PROVIDER_KEYRING=($(cd ./provider && yarn mnemonic | tee /dev/fd/3 | grep ':' | awk -F ': ' '{print $2}' )); } 3>&1

export PROVIDER_ADDRESS=${PROVIDER_KEYRING[1]}
export PROVIDER_MNEMONIC=${PROVIDER_KEYRING[2]}

docker compose up mongodb -d


echo "Dev env up! You can now interact with the provider-api."
echo "PROVIDER_ADDRESS $(echo $PROVIDER_ADDRESS)"
CONTAINER_NAME=$(docker ps -q -f name=provider-api)

# give the provider account some funds
echo "Sending funds to the Provider account and registering the provider"
docker exec -it $CONTAINER_NAME zsh -c 'yarn build && yarn setup provider'

docker exec -it $CONTAINER_NAME zsh