#!/usr/bin/env sh
set -eu

if [ -n "${BITBETTER_CERT_DATA:-}" ]; then
    mkdir -p /bitbetter/certs
    echo "${BITBETTER_CERT_DATA}" | base64 -d > /bitbetter/certs/bitbetter.cer
fi

bitbetter -o /bitbetter/licensing.cer -n /bitbetter/certs/bitbetter.cer -s .

exec /entrypoint.sh
