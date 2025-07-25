#!/bin/bash
set -euo pipefail

IMAGE=${1:-airflow-alpine-k8s:latest}

if ! command -v cosign >/dev/null 2>&1; then
    echo "cosign command not found" >&2
    exit 1
fi

docker build -t "$IMAGE" -f docker/Dockerfile .
cosign generate-key-pair --yes --output-key cosign.key --output-pub cosign.pub
COSIGN_PASSWORD="" cosign sign --key cosign.key "$IMAGE"
COSIGN_PASSWORD="" cosign verify --key cosign.pub "$IMAGE"
