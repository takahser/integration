#!/bin/bash
function usage() {
    cat <<USAGE

    Usage: $0 [--provider_register]

    Options:
        --provider_setup:  register, stake, and add dataset for provider

USAGE
    exit 1
}

PROVIDER_SETUP=false

while [ "$1" != "" ]; do
    case $1 in
    --provider_setup)
        PROVIDER_SETUP=true
        ;;
    -h | --help)
        usage # run usage function
        ;;
    *)
        usage
        exit 1
        ;;
    esac
    shift # remove the current value for `$1` and use the next
done

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
echo "PROVIDER_ADDRESS $(echo $PROVIDER_ADDRESS)"
CONTAINER_NAME=$(docker ps -q -f name=provider-api)

# give the provider account some funds
echo "Sending funds to the Provider account and registering the provider"
docker exec -it $CONTAINER_NAME zsh -c 'yarn setup provider'

#if [ PROVIDER_SETUP ]; then
#  echo "Registering the Provider account, staking, and adding a dataset"
#  docker exec -it $CONTAINER_NAME zsh -c 'yarn dev-provider-register && yarn dev-provider-stake && yarn dev-provider-dataset';
#fi

docker exec -it $CONTAINER_NAME zsh