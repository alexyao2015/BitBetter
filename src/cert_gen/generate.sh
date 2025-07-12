#!/usr/bin/env sh

set -eou pipefail

ROOT_DIR=$(realpath "$(dirname "$0")"/../..)
BW_VERSION=$(cat "${ROOT_DIR}"/bw_version.txt)

(
    cd "${ROOT_DIR}"
    BW_VERSION=$(cat bw_version.txt) docker buildx bake -f docker-bake.hcl bitbetter-certificate-gen
)
docker run --rm -v "$(realpath "$(dirname "$0")")"/certs:/certs bitbetter/certificate-gen:"${BW_VERSION}"
