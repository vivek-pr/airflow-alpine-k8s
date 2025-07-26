#!/bin/bash
set -euo pipefail

if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
    echo "docker not available, skipping docker build test" >&2
    exit 0
fi

docker build -t airflow-alpine-k8s:test -f docker/Dockerfile .
docker run --rm airflow-alpine-k8s:test airflow version
