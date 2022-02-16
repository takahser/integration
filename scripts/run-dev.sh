#!/bin/bash

# spin up the substrate node
docker compose up substrate-node -d
echo "Waiting for the substrate node to start up..."
SUBSTRATE_CONTAINER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -q -f name=substrate-node))
RESPONSE_CODE=$(curl -sI -o /dev/null -w "%{http_code}\n" $SUBSTRATE_CONTAINER_IP:9944)
while [ "$RESPONSE_CODE" != '400' ]; do
  RESPONSE_CODE=$(curl -sI -o /dev/null -w "%{http_code}\n" $SUBSTRATE_CONTAINER_IP:9944)
  sleep 1
done

docker compose up mongodb -d
docker compose up provider-api -d

CONTAINER_NAME=$(docker ps -q -f name=provider-api)

touch env

echo "Installing packages for redspot and building"
docker exec -t $CONTAINER_NAME zsh -c 'cd /usr/src/redspot && yarn && yarn build'

echo "Installing packages for protocol, building, and deploying contract"
docker exec -t $CONTAINER_NAME zsh -c "cd /usr/src/protocol && yarn && yarn build && { CONTRACT_ADDRESS=\$(yarn deploy | tee /dev/fd/3 | tail -n 2 | head -n 1 ); } 3>&1  && rm ../env && echo \"CONTRACT_ADDRESS=\$CONTRACT_ADDRESS\" >> ../env"

echo "Installing packages for dapp-example, building and deploying contract"
docker exec -t $CONTAINER_NAME zsh -c "cd /usr/src/dapp-example && yarn && yarn build && { DAPP_CONTRACT_ADDRESS=\$(yarn deploy | tee /dev/fd/3 | tail -n 2 | head -n 1 ); } 3>&1  && echo \"DAPP_CONTRACT_ADDRESS=\$DAPP_CONTRACT_ADDRESS\" >> ../env"

echo "Generating provider mnemonic"
docker exec -it $CONTAINER_NAME zsh -c '/usr/src/docker/dev.dockerfile.generate.provider.mnemonic.sh'

echo "Sending funds to the Provider account and registering the provider"
docker exec -it $CONTAINER_NAME zsh -c 'source env && yarn && yarn build && cd packages/core && yarn setup provider && yarn setup dapp'

echo "Dev env up! You can now interact with the provider-api."
docker exec -it --env-file ./env $CONTAINER_NAME zsh
