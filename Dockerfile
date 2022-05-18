# Build Stage
FROM ubuntu:20.04 as builder

## Install build dependencies.
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y cmake clang curl git-all build-essential
RUN curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
RUN ${HOME}/.cargo/bin/rustup default nightly
RUN ${HOME}/.cargo/bin/cargo install -f cargo-fuzz
#RUN mkdir memc-rs
RUN git clone https://github.com/memc-rs/memc-rs.git
WORKDIR /memc-rs
COPY Mayhemfile Mayhemfile
COPY fuzz_decode_binary.rs memcrs/fuzz/fuzz_targets/fuzz_decode_binary.rs
COPY binary_codec.rs memcrs/src/protocol/binary_codec.rs
WORKDIR /memc-rs/memcrs/fuzz
RUN ${HOME}/.cargo/bin/cargo fuzz build
WORKDIR /

# Package Stage
FROM ubuntu:20.04

COPY --from=builder /memc-rs/memcrs/fuzz/target/x86_64-unknown-linux-gnu/release/* /