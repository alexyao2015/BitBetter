#!/usr/bin/env bash

set -eou pipefail

BW_VERSION=${BW_VERSION:-$(cat bw_version.txt)}

# Master build script for all images

# Build bitbetter images
src/bitbetter/build.sh --tag bitbetter/api:${BW_VERSION} --target public --base ghcr.io/bitwarden/api:${BW_VERSION}
src/bitbetter/build.sh --tag bitbetter/identity:${BW_VERSION} --target public --base ghcr.io/bitwarden/identity:${BW_VERSION}
src/license_gen/build.sh --tag bitbetter/licensegen:${BW_VERSION} --target public --base none
src/cert_gen/build.sh --tag bitbetter/certificate-gen:${BW_VERSION} --target none --base none

# Build bitbetter custom images
src/bitbetter/build.sh --tag bitbetter/api-custom:${BW_VERSION} --target custom --base ghcr.io/bitwarden/api:${BW_VERSION}
src/bitbetter/build.sh --tag bitbetter/identity-custom:${BW_VERSION} --target custom --base ghcr.io/bitwarden/identity:${BW_VERSION}
src/license_gen/build.sh --tag bitbetter/licensegen-custom:${BW_VERSION} --target custom --base none
