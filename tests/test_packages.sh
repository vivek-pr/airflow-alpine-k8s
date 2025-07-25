#!/bin/bash
set -euo pipefail

required_packages=(bash postgresql-client redis su-exec)
for pkg in "${required_packages[@]}"; do
    if ! grep -q "$pkg" docker/Dockerfile; then
        echo "Package $pkg missing in Dockerfile" >&2
        exit 1
    fi
done
