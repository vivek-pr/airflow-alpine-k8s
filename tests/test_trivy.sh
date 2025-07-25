#!/bin/bash
set -euo pipefail

trivy config --exit-code 1 --quiet docker/Dockerfile
