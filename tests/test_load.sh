#!/bin/bash
set -euo pipefail

# Basic load test running multiple scheduler loops
if ! command -v docker >/dev/null 2>&1; then
    echo "docker command not found" >&2
    exit 1
fi

IMAGE=airflow-alpine-k8s:load

docker build -t "$IMAGE" -f docker/Dockerfile docker > /dev/null

echo "Starting load container"
docker run --rm "$IMAGE" bash -c 'airflow db init && airflow scheduler -D & for i in {1..5}; do airflow dags list >/dev/null; sleep 1; done'

echo "Load test completed"
