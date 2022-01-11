#!/bin/bash

# spin up the substrate node
docker compose up substrate-node -d
echo "Waiting for the substrate node to start up..."
sleep 10

# install protocol packages
$(cd protocol && yarn);

# deploy the example dapp contract and extract its address
{ DAPP_CONTRACT_ADDRESS=$(cd ./dapp-example && yarn deploy | tee /dev/fd/3 | grep 'contract address:' | awk -F ':  ' '{print $2}'); } 3>&1
export DAPP_CONTRACT_ADDRESS=$DAPP_CONTRACT_ADDRESS

# deploy prosopo contract and extract its address
{ CONTRACT_ADDRESS=$(cd ./protocol && yarn deploy | tee /dev/fd/3 | grep 'contract address:' | awk -F ':  ' '{print $2}'); } 3>&1
export CONTRACT_ADDRESS=$CONTRACT_ADDRESS

# install packages
$(cd provider && yarn);

# generate mnemonic for the provider
IFS=$'
'
{ PROVIDER_KEYRING=($(cd ./provider && yarn mnemonic | tee /dev/fd/3 | grep ':' | awk -F ': ' '{print $2}' )); } 3>&1

export PROVIDER_ADDRESS=${PROVIDER_KEYRING[0]}
export PROVIDER_MNEMONIC=${PROVIDER_KEYRING[1]}

# make sure the mnemonic is in the right format
MNEMONIC_COUNT=$(echo ${PROVIDER_KEYRING[1]} | wc -w);

if [[ $MNEMONIC_COUNT -ne 12 ]]; then

  echo "PROVIDER_MNEMONIC not set!"
  exit 1

else

  docker compose up mongodb -d
  docker compose up provider-api -d

  CONTAINER_NAME=$(docker ps -q -f name=provider-api)

  # give the provider account some funds
  echo "Sending funds to the Provider account and registering the provider"
  docker exec -it $CONTAINER_NAME zsh -c 'yarn build && yarn setup provider'

  echo "Dev env up! You can now interact with the provider-api."
  docker exec -it $CONTAINER_NAME zsh
fi