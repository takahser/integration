#!/bin/bash
# flags
function usage() {
    cat <<USAGE

    Usage: $0 [--build-redspot]

    Options:
        --build-redspot:      build the redspot library
        --build-provider:     build the provider library and setup dummy data
        --deploy-protocol:    deploy the prosopo protocol contract
        --deploy-dapp:        deploy the dapp-example contract
USAGE
    exit 1
}

# if no arguments are provided, return usage function
#if [ $# -eq 0 ]; then
#    echo "Usage function"
#    usage # run usage function
#    exit 1
#fi

BUILD_REDSPOT=false
BUILD_PROVIDER=false
DEPLOY_PROTOCOL=false
DEPLOY_DAPP=false

for arg in "$@"; do
    case $arg in
    --build-redspot)
        BUILD_REDSPOT=true
        shift # Remove --build_redspot from `$@`
        ;;
    --build-provider)
        BUILD_PROVIDER=true
        shift # Remove --build_provider from `$@`
        ;;
    --deploy-protocol)
        DEPLOY_PROTOCOL=true
        shift # Remove --deploy_protocol from `$@`
        ;;
    --deploy-dapp)
        DEPLOY_DAPP=true
        shift # Remove --deploy_dapp from `$@`
        ;;
    -h | --help)
        usage # run usage function on help
        ;;
    *)
        usage # run usage function if wrong argument provided
        ;;
    esac
done


# spin up the substrate node
docker compose up substrate-node -d
echo "Waiting for the substrate node to start up..."
SUBSTRATE_CONTAINER_NAME=$(docker ps -q -f name=substrate-node)
if [ -z "$SUBSTRATE_CONTAINER_NAME" ];
  then echo "Substrate container not running, exiting";
  exit 1
fi
SUBSTRATE_CONTAINER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $SUBSTRATE_CONTAINER_NAME)
RESPONSE_CODE=$(curl -sI -o /dev/null -w "%{http_code}\n" $SUBSTRATE_CONTAINER_IP:9944)
while [ "$RESPONSE_CODE" != '400' ]; do
  RESPONSE_CODE=$(curl -sI -o /dev/null -w "%{http_code}\n" $SUBSTRATE_CONTAINER_IP:9944)
  sleep 1
done

docker compose up mongodb -d
docker compose up provider-api -d

CONTAINER_NAME=$(docker ps -q -f name=provider-api)

rm env
touch env

if [[ $BUILD_REDSPOT == true ]];
  then echo "Installing packages for redspot and building"
  docker exec -t $CONTAINER_NAME zsh -c 'cd /usr/src/redspot && yarn && yarn build'
fi

if [[ $DEPLOY_PROTOCOL == true ]];
  then echo "Installing packages for protocol, building, and deploying contract"
  docker exec -t $CONTAINER_NAME zsh -c "/usr/src/docker/dev.dockerfile.deploy.contract.and.store.account.sh /usr/src/protocol CONTRACT_ADDRESS"
fi

if [[ $DEPLOY_DAPP == true ]];
  then echo "Installing packages for dapp-example, building and deploying contract"
  docker exec -t $CONTAINER_NAME zsh -c "/usr/src/docker/dev.dockerfile.deploy.contract.and.store.account.sh /usr/src/dapp-example DAPP_CONTRACT_ADDRESS"
fi

echo "Generating provider mnemonic"
docker exec -it $CONTAINER_NAME zsh -c '/usr/src/docker/dev.dockerfile.generate.provider.mnemonic.sh /usr/src/protocol'

if [[ $BUILD_PROVIDER == true ]];
  then echo "Sending funds to the Provider account and registering the provider"
  docker exec -it --env-file env $CONTAINER_NAME zsh -c 'yarn && yarn build && cd /usr/src/packages/provider/packages/core && yarn setup provider && yarn setup dapp'
fi

echo "Dev env up! You can now interact with the provider-api."
docker exec -it --env-file env $CONTAINER_NAME zsh
