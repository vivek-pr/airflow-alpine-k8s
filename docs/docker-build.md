# Docker Image Build Guide

This document explains how the Airflow Alpine image is built and how you can customise it for your environment.

## Requirements
- Docker 20.10+
- Internet access to fetch packages during the build

## Building the Image
Run the following command from the repository root:
```bash
docker build -t airflow-alpine -f docker/Dockerfile .
```
The Dockerfile installs the minimal set of Alpine packages required for Airflow. The resulting image is around 200MB.

All Python packages are installed using a dedicated `airflow` user so no system
directories are modified during the build. You can extend the image by copying
additional Python dependencies into `/opt/airflow/.local`.

## Customising
You can extend the image by creating your own Dockerfile that starts with `FROM airflow-alpine` and installs additional system packages or Python dependencies.

```Dockerfile
FROM airflow-alpine
RUN apk add --no-cache your-package
```

For a full list of packages installed in the base image, inspect `docker/Dockerfile`.
