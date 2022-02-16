# Integration
Integrates protocol and provider for development purposes

# Prerequisites
- node (tested on v16.13.2)
- docker (tested on v20.10.8, used 4CPUs, 6GB of memory, 2GB of swap)
- binaryen
- follow instructions to install the Substrate dependencies [here](https://docs.substrate.io/v3/getting-started/installation/)
  - if it asks you to run something like this `rustup component add rust-src --toolchain nightly-x86_64-apple-darwin` then please do it (OSX)
- cargo contract (`cargo install cargo-contract --vers ^0.16 --force --locked`)


# Usage
Start by pulling submodules using

`make setup`

And then run the `make dev` script, which will perform the following tasks:

1. Spins up a substrate node container
2. Builds and deploys the [prosopo protocol](https://github.com/prosopo-io/protocol/) contract using //Alice account, capturing resultant contract address in the environment variable `CONTRACT_ADDRESS`
2. Builds and deploys the [dapp-example](https://github.com/prosopo-io/dapp-example) contract using //Alice account, capturing resultant contract address in the environment variable `DAPP_CONTRACT_ADDRESS`
3. Generates a provider mnemonic and sets the `PROVIDER_MNEMONIC` and `PROVIDER_ADDRESS` environment variables locally
4. Spins up a mongodb container
5. Spins up the provider container, passing through environment variables `CONTRACT_ADDRESS`, `DAPP_CONTRACT_ADDRESS`, `PROVIDER_MNEMONIC`, and `PROVIDER_ADDRESS`
6. Builds redspot in the provider container
7. Builds the provider code in the provider container
8. Sets up the provider specified in `PROVIDER_MNEMONIC` and sets up the dapp specified in `DAPP_CONTRACT_ADDRESS`
9. Opens a `zsh` shell inside the provider container at `/usr/src/app`

`make dev`

Once `make dev` is complete, you will be in a shell in the provider container `/usr/src/app`, which is the root of the provider repo.

Dependencies should have been installed but you can install the dependencies using the following command if they are missing:

```bash
cd /usr/src/app && yarn
```

Default dev data should have been populated in the contract - one registered Provider and one Dapp. There will also be default captcha data in the mongoDB.

Now you can work interact with the provider CLI, start the API server, or run the tests.

## Tests

> Please note your `PROVIDER_MNEMONIC` environment variable must be set for the tests to run. You can check this with `echo $PROVIDER_MNEMONIC`

The provider tests can now be run from inside the container using

```bash
yarn test
```

## Command Line Interface

The `PROVIDER_MNEMONIC` env variable must be set for any commands that interact with the Prosopo contract.

### Register a provider

```bash
yarn start provider_register --fee=10 --serviceOrigin=https://localhost:8282 --payee=Provider --address ADDRESS
```

| Param | Description |
| --------------- | --------------- |
| Fee | The amount the Provider charges or pays per captcha approval / disapproval |
| serviceOrigin | The location of the Provider's service |
| Payee | Who is paid on successful captcha completion (`Provider` or `Dapp`) |
| Address | Address of the Provider |

### Update a provider

```bash
yarn start provider_update --fee=10 --serviceOrigin=https://localhost:8282 --payee=Provider --address ADDRESS
```

Params are the same as `provider_register`

### Add a dataset for a Provider

```bash
yarn start provider_add_data_set --file /usr/src/data/captchas.json
```

| Param | Description |
| --------------- | --------------- |
| File | JSON file containing captchas |

File format can be viewed [here](https://github.com/prosopo-io/provider/blob/master/tests/mocks/data/captchas.json).

### De-register a Provider

```bash
yarn start provider_deregister --address ADDRESS
```

| Param | Description |
| --------------- | --------------- |
| Address | Address of the Provider |

### Unstake funds

```bash
yarn start provider_unstake --value VALUE
```

| Param | Description |
| --------------- | --------------- |
| Value | The amount of funds to unstake from the contract |

### List Provider accounts in contract

```bash
yarn start provider_accounts
```



## API

Run the API server

```bash
yarn start --api
```

The API contains functions that will be required for the frontend captcha interface.

| API Resource | Function |
| --------------- | --------------- |
|`/v1/prosopo/random_provider/`| Get a random provider based on AccountId |
| `/v1/prosopo/providers/` | Get list of all provider IDs |
| `/v1/prosopo/dapps/` | Get list of all dapp IDs |
| `/v1/prosopo/provider/:providerAccount` | Get details of a specific Provider account |
| `/v1/prosopo/provider/captcha/:datasetId/:userAccount` | Get captchas to solve |
| `/v1/prosopo/provider/solution` | Submit captcha solutions |


## Dev Setup Script
The following commands can be run during development to populate the contract with dummy data.

| Command | Function | Executed during `make dev` |
| --------------- | --------------- | --------------- |
| Dev command to setup the provider stored in the env variable `PROVIDER_MNEMONIC` with dummy data |`yarn setup provider` | 🗸 |
| Dev command to setup the dapp contract stored in the env variable `DAPP_CONTRACT_ADDRESS` |`yarn setup dapp` | 🗸 |
| Dev command to respond to captchas from a `DAPP_USER` |`yarn setup user` | ✗ |
| Dev command to respond to captchas from a `DAPP_USER`, using the registered Provider to approve the response |`yarn setup user --approve` | ✗ |
| Dev command to respond to captchas from a `DAPP_USER`, using the registered Provider to disapprove the response |`yarn setup user --disapprove` | ✗ |

# Known problems & fixes
1. OSX nightly library missing:
```
error: "/Users/user/.rustup/toolchains/nightly-x86_64-apple-darwin/lib/rustlib/src/rust/Cargo.lock" does not exist, unable to build with the standard library, try:
        rustup component add rust-src --toolchain nightly-x86_64-apple-darwin
```
   - please try running:
  ```bash
  rustup install nightly-x86_64-apple-darwin
  rustup component add rust-src --toolchain nightly-x86_64-apple-darwin
  ```
