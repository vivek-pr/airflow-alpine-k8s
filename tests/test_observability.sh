#!/bin/bash
set -euo pipefail

for cmd in docker curl; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "$cmd command not found" >&2
        exit 1
    fi
done

# Build image
IMAGE=airflow-observability:test

docker build -t "$IMAGE" -f docker/Dockerfile .

CID=$(docker run -d -p 8080:8080 "$IMAGE")

# Wait for health status
for i in {1..30}; do
    status=$(docker inspect -f '{{.State.Health.Status}}' "$CID" || true)
    if [ "$status" = "healthy" ]; then
        break
    fi
    sleep 2
    if [ "$i" -eq 30 ]; then
        echo "Container did not become healthy" >&2
        docker logs "$CID"
        docker rm -f "$CID"
        exit 1
    fi
done

# Query health endpoint
curl -f http://localhost:8080/health

docker rm -f "$CID"
