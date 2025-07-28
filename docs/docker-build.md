# Docker Image Build Guide

This document explains how the Airflow image is built from the official Python Alpine base and how you can customise it for your environment.

## Requirements
- Docker 20.10+
- Internet access to fetch packages during the build

## Building the Image
Run the following command from the repository root:
```bash
docker build -t airflow-alpine -f docker/Dockerfile .
```
The Dockerfile relies on the `python:3.12-alpine3.21` base image and installs only Python packages. No system package manager is used during the build.

All Python packages are installed using a dedicated `airflow` user within a
virtual environment located at `/opt/airflow/.local`. You can extend the image
by copying additional Python dependencies into that environment.

Because the official Airflow constraints pin `dill` to a version without
prebuilt wheels for Python 3.12, the Dockerfile patches the constraints file so
`dill==0.3.9` is installed from a wheel and no compiler is required.

## Customising
You can extend the image by creating your own Dockerfile that starts with `FROM airflow-alpine` and installs additional Python dependencies.

```Dockerfile
FROM airflow-alpine
RUN pip install your-package
```

Avoid installing additional OS packages and rely on Python wheels to keep the image lightweight.
