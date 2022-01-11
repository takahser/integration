#!/bin/bash
git submodule update --init --recursive --force --checkout
cd ./redspot && yarn && yarn build && cd ..
cd ./protocol && yarn && cd ..
cd ./dapp-example && yarn && cd ..