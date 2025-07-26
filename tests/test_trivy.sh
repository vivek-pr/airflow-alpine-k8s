#!/bin/bash
set -euo pipefail

if ! command -v trivy >/dev/null 2>&1; then
    echo "trivy not available, skipping trivy test" >&2
    exit 0
fi

if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
    echo "docker not available, skipping trivy test" >&2
    exit 0
fi


trivy config --exit-code 1 --quiet docker/Dockerfile
docker build -t airflow-alpine-k8s:test -f docker/Dockerfile .
trivy image --exit-code 1 --quiet airflow-alpine-k8s:test
