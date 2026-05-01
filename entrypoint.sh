#!/usr/bin/env bash
# entrypoint.sh -- Prepare environment for cron and start cron daemon.
# Cron does NOT inherit container environment variables, so we dump them
# to /etc/environment which cron sources before each job.

set -euo pipefail

# Export all current env vars so cron jobs can access them
printenv | grep -v "no_proxy" >> /etc/environment

# Ensure log directory exists
mkdir -p /var/log/etl

# Install crontab
crontab /etc/cron.d/etl-cron

echo "[ENTRYPOINT] Environment written. Cron starting in foreground..."

# Start cron in foreground so the container stays alive
cron -f
