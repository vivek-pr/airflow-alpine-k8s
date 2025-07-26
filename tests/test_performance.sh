#!/bin/bash
set -euo pipefail

if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
    echo "docker not available, skipping performance test" >&2
    exit 0
fi

# Build official image for comparison
cat <<'DOCKERFILE' > /tmp/Dockerfile_official
FROM apache/airflow:3.0.3
DOCKERFILE

docker build -t airflow-official:compare -f /tmp/Dockerfile_official /tmp

time docker run --rm airflow-official:compare airflow info >/tmp/perf_official.txt 2>&1
TIME_OFFICIAL=$(grep real /tmp/perf_official.txt | awk '{print $2}')

docker build -t airflow-alpine-k8s:compare -f docker/Dockerfile .
time docker run --rm airflow-alpine-k8s:compare airflow info >/tmp/perf_alpine.txt 2>&1
TIME_ALPINE=$(grep real /tmp/perf_alpine.txt | awk '{print $2}')

echo "official_image_time=$TIME_OFFICIAL" 
echo "alpine_image_time=$TIME_ALPINE"

