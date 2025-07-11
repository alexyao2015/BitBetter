#!/usr/bin/env sh

set -eou pipefail

"$(dirname "$0")"/build.sh --tag certgen
docker run --rm -v "$(realpath "$(dirname "$0")")"/certs:/certs certgen
