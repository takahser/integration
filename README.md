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
Start by pulling submodules
`make setup`

And run the dev script, that would:
- spin up the contract node
- deploy the contract
- setup a node container with provider code

`make dev`

- Substrate might take 5 minutes to start for the first time, so will want to run `make dev` again (`make dev` is reliant on substrate running)

Install deps on the provider container:
`cd /usr/src/app && yarn`

Now you can work interact with the provider cli or start the api server.

# Known problems & fixes
1. OSX nigtly library missing:
```
error: "/Users/user/.rustup/toolchains/nightly-x86_64-apple-darwin/lib/rustlib/src/rust/Cargo.lock" does not exist, unable to build with the standard library, try:
        rustup component add rust-src --toolchain nightly-x86_64-apple-darwin
```
   - please try running: `rustup component add rust-src --toolchain nightly-x86_64-apple-darwin`
