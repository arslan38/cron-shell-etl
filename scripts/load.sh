#!/usr/bin/env bash
# load.sh -- Load transformed data into PostgreSQL using upsert (idempotent).

set -euo pipefail

TRANSFORMED_FILE="/tmp/transformed.csv"

DB_HOST="${POSTGRES_HOST:-postgres}"
DB_PORT="${POSTGRES_PORT:-5432}"
DB_NAME="${POSTGRES_DB:-etl_db}"
DB_USER="${POSTGRES_USER:-etl_user}"

export PGPASSWORD="${POSTGRES_PASSWORD:-etl_pass}"

# Wait for PostgreSQL to be ready
for i in $(seq 1 10); do
    if pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" > /dev/null 2>&1; then
        break
    fi
    echo "[LOAD] Waiting for PostgreSQL... ($i/10)"
    sleep 2
done

if ! pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" > /dev/null 2>&1; then
    echo "[LOAD] ERROR: PostgreSQL is not reachable."
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c \
        "INSERT INTO etl_log (status, rows_loaded, message) VALUES ('FAILURE', 0, 'PostgreSQL not reachable');"
    exit 1
fi

if [ ! -s "$TRANSFORMED_FILE" ]; then
    echo "[LOAD] No transformed data to load."
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c \
        "INSERT INTO etl_log (status, rows_loaded, message) VALUES ('SKIPPED', 0, 'No transformed data');"
    exit 0
fi

ROW_COUNT=0
SQL_STATEMENTS=""

while IFS=',' read -r sale_date category total_qty total_amount; do
    SQL_STATEMENTS="${SQL_STATEMENTS}
INSERT INTO sales_summary (sale_date, category, total_qty, total_amount, loaded_at)
VALUES ('${sale_date}', '${category}', ${total_qty}, ${total_amount}, NOW())
ON CONFLICT (sale_date, category)
DO UPDATE SET
    total_qty = sales_summary.total_qty + EXCLUDED.total_qty,
    total_amount = sales_summary.total_amount + EXCLUDED.total_amount,
    loaded_at = NOW();"
    ROW_COUNT=$((ROW_COUNT + 1))
done < "$TRANSFORMED_FILE"

# Execute all statements in a single transaction
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
BEGIN;
${SQL_STATEMENTS}
INSERT INTO etl_log (status, rows_loaded, message) VALUES ('SUCCESS', ${ROW_COUNT}, 'Batch loaded successfully');
COMMIT;
"

echo "[LOAD] Loaded $ROW_COUNT rows into sales_summary."
