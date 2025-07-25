#!/bin/sh
set -eu

# Drop privileges if running as root
if [ "$(id -u)" = "0" ]; then
    exec su-exec airflow "$@"
else
    exec "$@"
fi
