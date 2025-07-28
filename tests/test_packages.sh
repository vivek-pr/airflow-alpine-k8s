#!/bin/bash
set -euo pipefail

if ! grep -q "^FROM corporate-python" docker/Dockerfile; then
    echo "Dockerfile must use the corporate base image" >&2
    exit 1
fi

if grep -q "apk add" docker/Dockerfile; then
    echo "apk usage detected but package manager is restricted" >&2
    exit 1
fi
