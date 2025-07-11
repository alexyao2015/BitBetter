#!/usr/bin/env sh

# Remove any existing key files
[ ! -e "bitbetter.cer" ] || rm "bitbetter.cer"
[ ! -e "bitbetter.key" ]  || rm "bitbetter.key"

# Generate new keys
openssl req -x509 -newkey rsa:2048 -sha256 -nodes \
-keyout bitbetter.key \
-out bitbetter.cer \
-outform der \
-days 3650 \
-subj "/CN=1"

chmod 644 "bitbetter.cer" "bitbetter.key"
