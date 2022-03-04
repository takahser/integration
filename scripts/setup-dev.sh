#!/bin/bash
git submodule update --init --recursive --force --checkout
git checkout milestone1 --recurse-submodules