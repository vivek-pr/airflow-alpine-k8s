#!/bin/bash
set -euo pipefail

if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
    echo "docker not available, skipping performance test" >&2
    exit 0
fi

docker build -t airflow-alpine-k8s:compare -f docker/Dockerfile .
time docker run --rm airflow-alpine-k8s:compare airflow info >/tmp/perf_alpine.txt 2>&1
TIME_ALPINE=$(grep real /tmp/perf_alpine.txt | awk '{print $2}')

echo "alpine_image_time=$TIME_ALPINE"

