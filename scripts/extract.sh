#!/usr/bin/env bash
# extract.sh -- Read a batch of rows from sales_raw.csv using watermark-based tracking.

set -euo pipefail

DATA_FILE="/data/sales_raw.csv"
EXTRACTED_FILE="/tmp/extracted.csv"
WATERMARK_FILE="/var/log/etl/.watermark"
BATCH_SIZE=10

# Initialize watermark if missing (start after header = line 1)
if [ ! -f "$WATERMARK_FILE" ]; then
    echo "1" > "$WATERMARK_FILE"
fi

WATERMARK=$(cat "$WATERMARK_FILE")
TOTAL_LINES=$(wc -l < "$DATA_FILE")
# Total data lines = total lines minus header
DATA_LINES=$((TOTAL_LINES - 1))

if [ "$WATERMARK" -gt "$DATA_LINES" ]; then
    echo "[EXTRACT] No new data to extract. Watermark=$WATERMARK, DataLines=$DATA_LINES"
    exit 1
fi

# Extract batch: skip header (+1) and already-processed lines
SKIP=$((WATERMARK))  # lines to skip from top (including header)
tail -n +"$((SKIP + 1))" "$DATA_FILE" | head -n "$BATCH_SIZE" > "$EXTRACTED_FILE"

EXTRACTED_COUNT=$(wc -l < "$EXTRACTED_FILE")
NEW_WATERMARK=$((WATERMARK + EXTRACTED_COUNT))

echo "$NEW_WATERMARK" > "$WATERMARK_FILE"

echo "[EXTRACT] Extracted $EXTRACTED_COUNT rows (lines $((WATERMARK+1))-$((NEW_WATERMARK))) -> $EXTRACTED_FILE"
