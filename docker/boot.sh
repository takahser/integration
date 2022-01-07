#!/bin/sh
. ~/.cargo/env
exec cargo run --release -- --dev --tmp --unsafe-ws-external --prometheus-external -lerror,runtime::contracts=debug
