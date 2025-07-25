#!/bin/bash
set -euo pipefail

# Aggregate security checks
./tests/test_hadolint.sh
./tests/test_trivy.sh

echo "Security compliance checks passed"
