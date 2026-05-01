# cron + shell ETL Pipeline

**YZV322E Applied Data Engineering -- Tool Presentation #64**
Huzeyfe Burak Arslan (150200314)

## What is this tool?

`cron` is the Unix job scheduler (Vixie Cron, 1987) that runs commands at specified intervals. Combined with `bash` shell scripts, it provides a zero-dependency ETL orchestration solution -- the way data pipelines were automated before Airflow existed.

## Prerequisites

- Docker >= 20.10
- Docker Compose >= 2.0

## Installation

```bash
git clone https://github.com/arslan38/cron-shell-etl.git
cd cron-shell-etl
```

## Running the Example

```bash
docker-compose up --build
```

The pipeline processes 10 rows per minute from `data/sales_raw.csv`. After ~7 minutes all 61 rows will be processed. Watch the logs:

```bash
docker-compose logs -f cron-worker
```

## Expected Output

### Pipeline log (cron-worker)

```
=========================================
[PIPELINE] Run started at 2026-05-01 19:15:01
=========================================
[PIPELINE] Starting extract...
[EXTRACT] Extracted 10 rows (lines 2-11) -> /tmp/extracted.csv
[PIPELINE] Starting transform...
[TRANSFORM] Produced 7 aggregated rows -> /tmp/transformed.csv
[PIPELINE] Starting load...
[LOAD] Loaded 7 rows into sales_summary.
=========================================
[PIPELINE] Run completed at 2026-05-01 19:15:01
=========================================
```

After all rows are processed:

```
[PIPELINE] Starting extract...
[EXTRACT] No new data to extract. Watermark=62, DataLines=61
[PIPELINE] No new data. Pipeline complete.
```

### Query results

```bash
docker exec -it etl-postgres psql -U etl_user -d etl_db \
  -c "SELECT * FROM sales_summary ORDER BY sale_date, category;"
```

```
 sale_date  |  category   | total_qty | total_amount
------------+-------------+-----------+--------------
 2024-01-15 | Electronics |        14 |      4299.86
 2024-01-15 | Furniture   |         3 |       749.97
 2024-01-15 | Stationery  |        50 |       249.50
 2024-01-16 | Electronics |         7 |      1099.93
 ...
```

```bash
docker exec -it etl-postgres psql -U etl_user -d etl_db \
  -c "SELECT * FROM etl_log ORDER BY run_at DESC LIMIT 5;"
```

### Teardown

```bash
docker-compose down -v
```