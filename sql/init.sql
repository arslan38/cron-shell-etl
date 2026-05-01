CREATE TABLE IF NOT EXISTS sales_summary (
    sale_date   DATE        NOT NULL,
    category    VARCHAR(50) NOT NULL,
    total_qty   INTEGER     NOT NULL DEFAULT 0,
    total_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
    loaded_at   TIMESTAMP   NOT NULL DEFAULT NOW(),
    UNIQUE (sale_date, category)
);

CREATE TABLE IF NOT EXISTS etl_log (
    id          SERIAL PRIMARY KEY,
    run_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    status      VARCHAR(20) NOT NULL,
    rows_loaded INTEGER DEFAULT 0,
    message     TEXT
);
