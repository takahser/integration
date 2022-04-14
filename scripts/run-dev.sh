#!/bin/bash

# spin up the substrate node
docker compose up substrate-node -d --no-build
echo "Waiting for the substrate node to start up..."
SUBSTRATE_CONTAINER_NAME=$(docker ps -q -f name=substrate-node)
if [ -z "$SUBSTRATE_CONTAINER_NAME" ];
  then echo "Substrate container not running, exiting";
  exit 1
fi
SUBSTRATE_CONTAINER_URL="0.0.0.0:9944"
RESPONSE_CODE=$(curl -sI -o /dev/null -w "%{http_code}\n" $SUBSTRATE_CONTAINER_URL)
while [ "$RESPONSE_CODE" != '400' ]; do
  RESPONSE_CODE=$(curl -sI -o /dev/null -w "%{http_code}\n" $SUBSTRATE_CONTAINER_URL)
  sleep 1
done

docker compose up mongodb -d
docker compose up provider-api -d

CONTAINER_NAME=$(docker ps -q -f name=provider-api)

# create an empty env file
rm -f env
touch env

echo "Installing packages for redspot and building"
docker exec -t $CONTAINER_NAME zsh -c 'cd /usr/src/redspot && yarn && yarn build'

echo "Installing packages for protocol, building, and deploying contract"
docker exec -t $CONTAINER_NAME zsh -c "/usr/src/docker/dev.dockerfile.deploy.contract.and.store.account.sh /usr/src/protocol CONTRACT_ADDRESS"

echo "Installing packages for dapp-example, building and deploying contract"
docker exec -t $CONTAINER_NAME zsh -c "/usr/src/docker/dev.dockerfile.deploy.contract.and.store.account.sh /usr/src/dapp-example DAPP_CONTRACT_ADDRESS"

echo "Generating provider mnemonic"
docker exec -it $CONTAINER_NAME zsh -c '/usr/src/docker/dev.dockerfile.generate.provider.mnemonic.sh /usr/src/protocol'

echo "Linking artifacts to provider folder"
docker exec -it $CONTAINER_NAME zsh -c 'ln -sfn /usr/src/protocol/artifacts /usr/src/provider/artifacts'

echo "Sending funds to the Provider account and registering the provider"
docker exec -it --env-file env $CONTAINER_NAME zsh -c 'printenv && cd /usr/src/provider && yarn && yarn build && yarn setup provider && yarn setup dapp'

echo "Dev env up! You can now interact with the provider-api."
docker exec -it --env-file env $CONTAINER_NAME zsh
