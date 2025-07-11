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
        *)
            # Allow arbitrary arguments for code reuse
            shift 2
            ;;
    esac
done

if [ -z "${tag:-}" ] || [ -z "${target:-}" ]; then
    echo "Error: Tag (--tag), and target (--target) are required"
    echo "Usage: $0 --tag <tag> --target <target>" 
    exit 1
fi

(
    cd "$(dirname "$0")"/../..
    docker build -f src/license_gen/Dockerfile \
        -t "${tag}" \
        --target "${target}" \
        --progress=plain \
        .
)
