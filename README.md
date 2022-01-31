# Integration
Integrates protocol and provider for development purposes

# Prerequisites
- node (tested on v16.13.2)
- docker (tested on v20.10.8, used 4CPUs, 6GB of memory, 2GB of swap)
- binaryen
- follow instructions to install the Substrate dependencies [here](https://docs.substrate.io/v3/getting-started/installation/)
- cargo contract (`cargo install cargo-contract --vers ^0.16 --force --locked`)
- follow instructions to install dependencies in [protocol/README.md](./protocol/README.md)
- if it asks you to run something like this `rustup component add rust-src --toolchain nightly-x86_64-apple-darwin` then please do it (OSX)

# Usage
Start by pulling submodules using

`make setup`

And run the dev script, which will perform the following tasks:
- spin up substrate in a container, running in contracts mode
- deploy the [dapp-example](https://github.com/prosopo-io/dapp-example) contract
- deploy the [prosopo](https://github.com/prosopo-io/protocol/) contract
- setup a container with the provider code
- setup a mongoDB container

`make dev`

- Substrate might take a few minutes to start for the first time, so you will want to run `make dev` again (`make dev` is reliant on substrate running)

Once `make dev` is complete, you will be in a shell in the provider container.

Dependencies should have been installed but you can install the dependencies using the following command if they are missing:

```bash
cd /usr/src/app && yarn
```

Default dev data should have been populated in the contract - one registered Provider and one Dapp. There will also be default captcha data in the mongoDB.

Now you can work interact with the provider cli or start the api server.

# CLI

The `PROVIDER_MNEMONIC` env variable must be set for any commands that interact with the Prosopo contract.

## Register a provider

```bash
yarn start provider_register --fee=10 --serviceOrigin=https://localhost:8282 --payee=Provider --address ADDRESS
```

| Param | Description |
| --------------- | --------------- |
| Fee | The amount the Provider charges or pays per captcha approval / disapproval |
| serviceOrigin | The location of the Provider's service |
| Payee | Who is paid on successful captcha completion (`Provider` or `Dapp`) |
| Address | Address of the Provider |

## Update a provider

```bash
yarn start provider_update --fee=10 --serviceOrigin=https://localhost:8282 --payee=Provider --address ADDRESS
```

Params are the same as `provider_register`

## Add a dataset for a Provider

```bash
yarn start provider_add_data_set --file /usr/src/data/captchas.json
```

| Param | Description |
| --------------- | --------------- |
| File | JSON file containing details of captchas |

# API

Run the API server

```bash
yarn start --api
```

# Dev Setup Script
The following commands can be run during development to populate the contract with dummy data.

| Command | Function | Executed during `make dev` |
| --------------- | --------------- | --------------- |
| Dev command to setup the provider stored in the env variable `PROVIDER_MNEMONIC` with dummy data |`yarn setup provider` | 🗸 |
| Dev command to setup the dapp contract stored in the env variable `DAPP_CONTRACT_ADDRESS` |`yarn setup dapp` | 🗸 |
| Dev command to respond to captchas from a `DAPP_USER` |`yarn setup user` | ✗ |
| Dev command to respond to captchas from a `DAPP_USER`, using the registered Provider to approve the response |`yarn setup user --approve` | ✗ |
| Dev command to respond to captchas from a `DAPP_USER`, using the registered Provider to disapprove the response |`yarn setup user --disapprove` | ✗ |

# Known problems & fixes
1. OSX nigtly library missing:
```
error: "/Users/user/.rustup/toolchains/nightly-x86_64-apple-darwin/lib/rustlib/src/rust/Cargo.lock" does not exist, unable to build with the standard library, try:
        rustup component add rust-src --toolchain nightly-x86_64-apple-darwin
```
   - please try running: `rustup component add rust-src --toolchain nightly-x86_64-apple-darwin`
