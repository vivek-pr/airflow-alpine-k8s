#!/usr/bin/env sh
set -eu

# Healthcheck for Airflow API server or Webserver.
# Tries API first, then Web UI.

HOST=${HEALTH_HOST:-127.0.0.1}
PORT=${HEALTH_PORT:-8080}
BASE="http://${HOST}:${PORT}"

check_path() {
  url="$1"
  # Fetch body; do not fail on non-200 here, rely on content match
  body=$(wget -qO- "$url" 2>/dev/null || true)
  # Look for a generic status field seen in both API and UI health endpoints
  echo "$body" | grep -q '"status"' && return 0
  # As a fallback, API may expose version endpoint
  echo "$body" | grep -q '"version"' && return 0
  return 1
}

if check_path "$BASE/api/v1/health"; then
  exit 0
fi

if check_path "$BASE/health"; then
  exit 0
fi

# Final fallback: API version endpoint
if check_path "$BASE/api/v1/version"; then
  exit 0
fi

exit 1

