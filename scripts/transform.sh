#!/usr/bin/env bash
# transform.sh -- Clean, validate, deduplicate, and aggregate extracted CSV data.

set -euo pipefail

EXTRACTED_FILE="/tmp/extracted.csv"
TRANSFORMED_FILE="/tmp/transformed.csv"

if [ ! -s "$EXTRACTED_FILE" ]; then
    echo "[TRANSFORM] No extracted data to transform."
    exit 1
fi

# AWK pipeline:
# 1. Skip rows with empty quantity or negative unit_price
# 2. Normalize region to Title Case
# 3. Deduplicate by transaction_id (keep first occurrence)
# 4. Compute total_amount = quantity * unit_price
# 5. Aggregate by date + category: sum(quantity), sum(total_amount)
awk -F',' '
BEGIN { OFS="," }
{
    tid   = $1
    dt    = $2
    prod  = $3
    cat   = $4
    qty   = $5
    price = $6
    reg   = $7

    # Skip empty quantity
    if (qty == "" || qty+0 != qty) next

    # Skip negative price
    if (price+0 < 0) next

    # Deduplicate by transaction_id
    if (tid in seen) next
    seen[tid] = 1

    # Normalize category (trim whitespace)
    gsub(/^[ \t]+|[ \t]+$/, "", cat)

    # Normalize date
    gsub(/^[ \t]+|[ \t]+$/, "", dt)

    # Compute total
    total = qty * price

    # Aggregate by date + category
    key = dt SUBSEP cat
    agg_qty[key] += qty
    agg_amt[key] += total
}
END {
    for (key in agg_qty) {
        split(key, parts, SUBSEP)
        printf "%s,%s,%d,%.2f\n", parts[1], parts[2], agg_qty[key], agg_amt[key]
    }
}
' "$EXTRACTED_FILE" > "$TRANSFORMED_FILE"

ROW_COUNT=$(wc -l < "$TRANSFORMED_FILE")
echo "[TRANSFORM] Produced $ROW_COUNT aggregated rows -> $TRANSFORMED_FILE"
