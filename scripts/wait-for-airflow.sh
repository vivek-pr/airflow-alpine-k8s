#!/usr/bin/env sh
set -eu

# Wait for Airflow webserver, scheduler, and triggerer to become healthy

WEB_URL=${WEB_URL:-http://127.0.0.1:8080}
SLEEP=${SLEEP:-3}
RETRIES=${RETRIES:-100}

check_web() {
  wget -qO- "$WEB_URL/health" 2>/dev/null | grep -q '"status": "healthy"'
}

check_job() {
  airflow jobs check --job-type "$1" >/dev/null 2>&1
}

echo "Waiting for Airflow webserver at $WEB_URL ..."
i=0
until check_web; do
  i=$((i+1))
  if [ "$i" -gt "$RETRIES" ]; then
    echo "Timed out waiting for webserver health" >&2
    exit 1
  fi
  sleep "$SLEEP"
done
echo "Webserver healthy."

echo "Waiting for scheduler..."
i=0
until check_job SchedulerJob; do
  i=$((i+1))
  [ "$i" -gt "$RETRIES" ] && echo "Scheduler not healthy" >&2 && exit 1
  sleep "$SLEEP"
done
echo "Scheduler healthy."

echo "Waiting for triggerer..."
i=0
until check_job TriggererJob; do
  i=$((i+1))
  [ "$i" -gt "$RETRIES" ] && echo "Triggerer not healthy" >&2 && exit 1
  sleep "$SLEEP"
done
echo "Triggerer healthy."
