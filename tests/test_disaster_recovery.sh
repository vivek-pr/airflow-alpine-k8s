#!/bin/bash
set -euo pipefail

# Disaster recovery test backing up and restoring the Airflow DB
if ! command -v docker >/dev/null 2>&1; then
    echo "docker command not found" >&2
    exit 1
fi

IMAGE=airflow-alpine-k8s:recovery

docker build -t "$IMAGE" -f docker/Dockerfile docker > /dev/null

# Start a container with a volume for the database
CONTAINER=$(docker run -d "$IMAGE" bash -c 'airflow db init && sleep 300')
trap 'docker rm -f "$CONTAINER" >/dev/null' EXIT

sleep 5

docker exec "$CONTAINER" airflow db export /tmp/backup.sql

docker exec "$CONTAINER" bash -c 'airflow db reset -y && airflow db import /tmp/backup.sql'

echo "Disaster recovery test succeeded"
