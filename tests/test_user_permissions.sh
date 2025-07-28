#!/bin/bash
set -euo pipefail

if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
    echo "docker not available, skipping user permissions test" >&2
    exit 0
fi

IMAGE=airflow-alpine-k8s:user-test

docker build -t "$IMAGE" -f docker/Dockerfile .
uid=$(docker run --rm "$IMAGE" id -u)
gid=$(docker run --rm "$IMAGE" id -g)
home=$(docker run --rm "$IMAGE" sh -c 'echo "$HOME"')

if [ "$uid" != "50000" ] || [ "$gid" != "50000" ]; then
    echo "Expected UID/GID 50000, got ${uid}:${gid}" >&2
    exit 1
fi

if [ "$home" != "/opt/airflow" ]; then
    echo "Expected home directory /opt/airflow" >&2
    exit 1
fi

perms=$(docker run --rm "$IMAGE" sh -c "stat -c '%u:%g' /opt/airflow")
if [ "$perms" != "50000:50000" ]; then
    echo "Incorrect permissions on /opt/airflow" >&2
    exit 1
fi


pkgperms=$(docker run --rm "$IMAGE" sh -c "stat -c '%u:%g' /opt/airflow/.local")
if [ "$pkgperms" != "50000:50000" ]; then
    echo "Incorrect permissions on /opt/airflow/.local" >&2
    exit 1
fi

