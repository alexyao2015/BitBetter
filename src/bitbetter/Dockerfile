ARG BITWARDEN_BASE
FROM rust:alpine AS bitbetter_builder

WORKDIR /build

# Install dependencies
RUN apk add --no-cache \
    musl-dev \
    openssl-dev \
    openssl-libs-static

# Create a dummy main.rs file for caching
RUN mkdir src \
    && echo "fn main() {}" > src/main.rs

COPY Cargo.lock Cargo.toml ./

RUN cargo build --release

COPY src ./src

# Force cargo to detect the new main.rs file
RUN touch src/main.rs \
    && cargo build --release

FROM alpine:latest AS certdownloader

RUN wget https://github.com/bitwarden/server/raw/refs/heads/main/src/Core/licensing.cer

FROM ${BITWARDEN_BASE} AS base

COPY rootfs /
COPY --from=certdownloader /licensing.cer /bitbetter/
COPY --from=bitbetter_builder /build/target/release/bitbetter /usr/bin/bitbetter

FROM base AS public

COPY --from=certs . /bitbetter/certs

RUN bitbetter -o /bitbetter/licensing.cer -n /bitbetter/certs/bitbetter.cer -s .

FROM base AS custom

ENTRYPOINT [ "/bitbetter-entrypoint.sh" ]
