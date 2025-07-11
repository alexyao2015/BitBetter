ARG BITWARDEN_BASE
FROM alpine:latest AS certdownloader

RUN wget https://github.com/bitwarden/server/raw/refs/heads/main/src/Core/licensing.cer

FROM ${BITWARDEN_BASE} AS base

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ripgrep \
        xxd \
    && rm -rf /var/lib/apt/lists/*

COPY rootfs /
COPY --from=certdownloader /licensing.cer /bitbetter

FROM base AS public

COPY --from=certs . /bitbetter/certs

RUN /bitbetter/patch.sh

FROM base AS custom

ENTRYPOINT [ "/bitbetter-entrypoint.sh" ]
