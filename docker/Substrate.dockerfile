FROM debian:bookworm-slim AS base

RUN apt update
RUN apt install build-essential -y
RUN apt install -y git clang curl libssl-dev llvm libudev-dev
RUN apt install -y pkg-config libssl-dev
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

RUN . ~/.cargo/env && \
    rustup default stable &&\
    rustup update &&\
    rustup update nightly &&\
    rustup target add wasm32-unknown-unknown --toolchain nightly

RUN . ~/.cargo/env && \
    git clone https://github.com/paritytech/substrate

RUN . ~/.cargo/env && \
    cd substrate && \
    cargo build --locked --release

EXPOSE 9615
EXPOSE 9944
EXPOSE 9933

WORKDIR "substrate"

RUN stat ./target/release/

#ENTRYPOINT ["tail", "-f", "/dev/null"]
COPY ./Substrate.dockerfile.boot.sh /home/root/boot.sh
USER root
RUN chmod +x /home/root/boot.sh
CMD /home/root/boot.sh
