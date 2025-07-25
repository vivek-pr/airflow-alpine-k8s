#!/bin/bash
set -euo pipefail

if ! command -v hadolint >/dev/null 2>&1; then
    echo "hadolint command not found" >&2
    exit 1
fi

hadolint docker/Dockerfile
