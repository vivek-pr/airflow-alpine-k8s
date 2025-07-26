#!/bin/bash
set -euo pipefail

IMAGE=${1:-airflow-alpine-k8s:latest}

if ! command -v cosign >/dev/null 2>&1; then
    echo "cosign command not found" >&2
    exit 1
fi

if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
    echo "docker not available, skipping image signing test" >&2
    exit 0
fi

docker build -t "$IMAGE" -f docker/Dockerfile .

# Generate keys non-interactively; cosign writes cosign.key and cosign.pub
COSIGN_PASSWORD="" cosign generate-key-pair --output-key-prefix cosign

# Save the image as a tarball and sign it locally to avoid registry access
docker save "$IMAGE" -o image.tar
COSIGN_PASSWORD="" cosign sign-blob --key cosign.key --output image.tar.sig image.tar
COSIGN_PASSWORD="" cosign verify-blob --key cosign.pub --signature image.tar.sig image.tar

