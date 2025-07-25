#!/bin/bash
set -euo pipefail

if ! command -v kube-score >/dev/null 2>&1; then
    echo "kube-score command not found" >&2
    exit 1
fi

if ! find k8s -name '*.yaml' -print0 | xargs -0 kube-score score; then
    echo "kube-score found issues" >&2
fi
