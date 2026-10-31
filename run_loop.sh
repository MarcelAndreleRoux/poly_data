#!/usr/bin/env bash
# Keep the poly_data pipeline collecting: markets -> chain -> process, then sleep.
# Every stage is resumable upstream, so a crash or restart just picks up the delta.
#   POLL_INTERVAL_S   seconds between successful runs        (default 900 = 15 min)
#   RETRY_INTERVAL_S  seconds to wait after a failed run      (default 300)
#   HYPERSYNC_API     Envio HyperSync bearer token            (required by the chain stage)
set -u
cd /app
POLL_INTERVAL_S="${POLL_INTERVAL_S:-900}"
RETRY_INTERVAL_S="${RETRY_INTERVAL_S:-300}"

ts() { date -u +"%Y-%m-%d %H:%M:%S UTC"; }

while true; do
  if [ -z "${HYPERSYNC_API:-}" ] || [ "${HYPERSYNC_API}" = "your-token-here" ]; then
    echo "[$(ts)] HYPERSYNC_API is not set. Create a free token with HyperSync access at"
    echo "        https://envio.dev/app/api-tokens, put it in poly_data/.env, then:"
    echo "        docker compose up -d --force-recreate"
    echo "[$(ts)] waiting 10 minutes before checking again (no API calls made)"
    sleep 600
    continue
  fi
  echo "[$(ts)] pipeline run starting"
  if uv run --frozen poly-data; then
    echo "[$(ts)] pipeline run finished; next run in ${POLL_INTERVAL_S}s"
    sleep "${POLL_INTERVAL_S}"
  else
    echo "[$(ts)] pipeline run FAILED (exit $?); retrying in ${RETRY_INTERVAL_S}s"
    sleep "${RETRY_INTERVAL_S}"
  fi
done
