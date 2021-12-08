# Integration
Integrates protocol and provider for development purposes

# Prerequisites
- docker
- follow instructions to install dependencies in protocol/README.md

# Usage
Start by pulling submodules
`make setup`

And run the dev script, that would:
- spin up the contract node
- deploy the contract
- setup a node container with provider code

`make dev`

Install deps on the provider container:
`cd /usr/src/app && yarn`

Now you can work interact with the provider cli or start the api server.

