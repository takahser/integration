#!/bin/bash

#!!!!!!!!! FOLLOW SUBSTRATE SETUP INITIALLY AT https://docs.substrate.io/v3/getting-started/installation/ !!!!!!!!!!!!!!

# spin up the substrate node
docker compose up substrate-node -d
echo "Waiting for the substrate node to start up..."
SUBSTRATE_CONTAINER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -q -f name=substrate-node))
RESPONSE_CODE=$(curl -sI -o /dev/null -w "%{http_code}\n" $SUBSTRATE_CONTAINER_IP:9944)
while [ "$RESPONSE_CODE" != '400' ];
  do RESPONSE_CODE=$(curl -sI -o /dev/null -w "%{http_code}\n" $SUBSTRATE_CONTAINER_IP:9944);
  sleep 1;
done;

# install protocol packages
$(cd protocol && yarn);

# Install the contract builder
cargo install cargo-contract --vers ^0.16 --force --locked

# deploy prosopo contract and extract its address
{ CONTRACT_ADDRESS=$(cd ./protocol && yarn deploy | tee /dev/fd/3 | grep 'contract address:' | awk -F ':  ' '{print $2}'); } 3>&1
export CONTRACT_ADDRESS=$CONTRACT_ADDRESS

# deploy the example dapp contract and extract its address
{ DAPP_CONTRACT_ADDRESS=$(cd ./dapp-example && yarn deploy | tee /dev/fd/3 | grep 'contract address:' | awk -F ':  ' '{print $2}'); } 3>&1
export DAPP_CONTRACT_ADDRESS=$DAPP_CONTRACT_ADDRESS

# generate a mnemonic for the provider
IFS=$'
'
yarn
{ PROVIDER_KEYRING=($(cd ./protocol && yarn mnemonic | tee /dev/fd/3 | grep ':' | awk -F ': ' '{print $2}' )); } 3>&1

export PROVIDER_ADDRESS=${PROVIDER_KEYRING[0]}
export PROVIDER_MNEMONIC=${PROVIDER_KEYRING[1]}

# make sure the mnemonic is in the right format
MNEMONIC_COUNT=$(echo ${PROVIDER_KEYRING[1]} | wc -w);

if [[ $MNEMONIC_COUNT -ne 12 ]]; then

  echo "PROVIDER_MNEMONIC not set!"
  echo "Provider keyring index 0:  ${echo $PROVIDER_KEYRING[0]}"
  echo "Provider keyring index 1:  ${echo $PROVIDER_KEYRING[1]}"
  echo "Provider keyring index 2:  ${echo $PROVIDER_KEYRING[2]}"
  exit 1
else
  echo "PROVIDER_MNEMONIC set"
fi

docker compose up mongodb -d
docker compose up provider-api -d

CONTAINER_NAME=$(docker ps -q -f name=provider-api)

echo "Installing packages for redspot and building"
docker exec -it $CONTAINER_NAME zsh -c 'cd /usr/src/redspot && yarn && yarn build'

echo "Sending funds to the Provider account and registering the provider"
docker exec -it $CONTAINER_NAME zsh -c 'yarn && yarn build && yarn setup provider && yarn setup dapp'

echo "Dev env up! You can now interact with the provider-api."
docker exec -it $CONTAINER_NAME zsh
