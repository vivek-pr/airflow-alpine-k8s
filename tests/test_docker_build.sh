#!/bin/bash
set -euo pipefail

# Simple unit test to ensure Dockerfile builds without error
if ! command -v docker >/dev/null 2>&1; then
    echo "docker command not found" >&2
    exit 1
fi

docker build -t airflow-alpine-k8s:test -f docker/Dockerfile docker

echo "Docker build succeeded"
