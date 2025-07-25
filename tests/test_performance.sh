#!/bin/bash
set -euo pipefail

# Performance test comparing startup time of alpine vs official images
if ! command -v docker >/dev/null 2>&1; then
    echo "docker command not found" >&2
    exit 1
fi

ALPINE_IMAGE=airflow-alpine-k8s:perf
OFFICIAL_IMAGE=apache/airflow:2.7.3

echo "Building Alpine image"
docker build -t "$ALPINE_IMAGE" -f docker/Dockerfile docker > /dev/null

echo "Measuring Alpine image startup"
ALPINE_TIME=$( { time docker run --rm "$ALPINE_IMAGE" airflow version >/dev/null; } 2>&1 | grep real | awk '{print $2}')

echo "Measuring official image startup"
OFFICIAL_TIME=$( { time docker run --rm "$OFFICIAL_IMAGE" airflow version >/dev/null; } 2>&1 | grep real | awk '{print $2}')

echo "Alpine startup: $ALPINE_TIME"
echo "Official startup: $OFFICIAL_TIME"
