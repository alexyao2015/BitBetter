#!/usr/bin/env bash

set -eou pipefail

while [ $# -gt 0 ]; do
    case "$1" in
        --tag)
            tag="$2"
            shift 2
            ;;
        --target)
            target="$2" 
            shift 2
            ;;
        --base)
            base="$2"
            shift 2
            ;;
        *)
            echo "Usage: $0 --tag <tag> --target <target> --base <base>"
            exit 1
            ;;
    esac
done

if [ -z "${tag:-}" ] || [ -z "${target:-}" ] || [ -z "${base:-}" ]; then
    echo "Error: Tag (--tag), target (--target), and base (--base) are required"
    echo "Usage: $0 --tag <tag> --target <target> --base <base>" 
    exit 1
fi

(
    cd "$(dirname "$0")"/../..
    docker build -f src/bitbetter/Dockerfile \
        -t "${tag}" \
        --build-arg BITWARDEN_BASE="${base}" \
        --target "${target}" \
        --progress=plain \
        .
)
