#!/usr/bin/env sh

set -eou pipefail

while [ $# -gt 0 ]; do
    case "$1" in
        --tag)
            tag="$2"
            shift 2
            ;;
        *)
            # Allow arbitrary arguments for code reuse
            shift 2
            ;;
    esac
done

if [ -z "${tag:-}" ]; then
    echo "Error: Tag (--tag) is required"
    echo "Usage: $0 --tag <tag>" 
    exit 1
fi


(
    cd "$(dirname "$0")"/docker
    docker build -t "${tag}" .
)
