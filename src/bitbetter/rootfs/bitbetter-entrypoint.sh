#!/usr/bin/env sh

bitbetter -o /bitbetter/licensing.cer -n /bitbetter/certs/bitbetter.cer -s .

exec /entrypoint.sh
