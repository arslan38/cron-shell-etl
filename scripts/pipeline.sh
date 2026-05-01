#!/usr/bin/env bash
# pipeline.sh -- Main ETL orchestrator. Called by cron every minute.

set -euo pipefail

LOG_DIR="/var/log/etl"
mkdir -p "$LOG_DIR"

timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

echo "========================================="
echo "[PIPELINE] Run started at $(timestamp)"
echo "========================================="

# Step 1: Extract
echo "[PIPELINE] Starting extract..."
if ! /scripts/extract.sh; then
    echo "[PIPELINE] No new data. Pipeline complete at $(timestamp)"
    exit 0
fi

# Step 2: Transform
echo "[PIPELINE] Starting transform..."
/scripts/transform.sh

# Step 3: Load
echo "[PIPELINE] Starting load..."
/scripts/load.sh

echo "========================================="
echo "[PIPELINE] Run completed at $(timestamp)"
echo "========================================="
