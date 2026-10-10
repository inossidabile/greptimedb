CREATE TABLE json2_add_column (
    ts TIMESTAMP TIME INDEX,
    host STRING PRIMARY KEY,
    attrs JSON2 (
        http.status BIGINT
    )
) WITH (
    'append_mode' = 'true'
);

INSERT INTO json2_add_column VALUES
    (1, 'a', '{"http":{"status":200}}'),
    (2, 'b', '{"http":{"status":502}}');

ADMIN FLUSH_TABLE('json2_add_column');

INSERT INTO json2_add_column VALUES
    (3, 'a', '{"http":{"status":404}}');

ALTER TABLE json2_add_column
    ADD COLUMN IF NOT EXISTS trace_ctx JSON2 (
        max_auto_expanded_paths = 16,
        trace_id STRING INVERTED INDEX,
        parent.span_id STRING,
        duration_ms BIGINT,
        sampled BOOLEAN
    ) NULL AFTER host,
    ADD COLUMN IF NOT EXISTS baggage JSON2 NULL;

-- Applying the same migration again is a no-op.
ALTER TABLE json2_add_column
    ADD COLUMN IF NOT EXISTS trace_ctx JSON2 (
        max_auto_expanded_paths = 16,
        trace_id STRING INVERTED INDEX,
        parent.span_id STRING,
        duration_ms BIGINT,
        sampled BOOLEAN
    ) NULL AFTER host,
    ADD COLUMN IF NOT EXISTS baggage JSON2 NULL;

SHOW CREATE TABLE json2_add_column;

-- Rows written before the columns existed, from both SST and memtable.
SELECT ts, host, trace_ctx.trace_id, trace_ctx.parent.span_id, baggage.tenant
FROM json2_add_column
ORDER BY ts;

SELECT count(*) FROM json2_add_column WHERE trace_ctx.trace_id IS NULL;

-- Writers that don't know the new columns keep working.
INSERT INTO json2_add_column (ts, host, attrs) VALUES
    (4, 'b', '{"http":{"status":201}}');

INSERT INTO json2_add_column (ts, host, attrs, trace_ctx, baggage) VALUES
    (5, 'a', '{"http":{"status":200}}', '{"trace_id":"t-5","parent":{"span_id":"s-5"},"duration_ms":12,"sampled":true}', '{"tenant":"acme"}'),
    (6, 'b', '{"http":{"status":500}}', '{"trace_id":"t-6"}', NULL);

-- Type hints of the added column are enforced.
INSERT INTO json2_add_column (ts, host, trace_ctx) VALUES
    (7, 'a', '{"duration_ms":"slow"}');

INSERT INTO json2_add_column (ts, host, trace_ctx) VALUES
    (8, 'a', '{"sampled":"yes"}');

SELECT ts, trace_ctx.trace_id, trace_ctx.parent.span_id, trace_ctx.duration_ms, trace_ctx.sampled, baggage.tenant
FROM json2_add_column
ORDER BY ts;

SELECT arrow_typeof(trace_ctx.duration_ms), arrow_typeof(trace_ctx.sampled)
FROM json2_add_column
WHERE ts = 5;

SELECT ts FROM json2_add_column WHERE trace_ctx.trace_id = 't-6';

ADMIN FLUSH_TABLE('json2_add_column');

SELECT ts, trace_ctx.trace_id, trace_ctx.parent.span_id, baggage.tenant
FROM json2_add_column
ORDER BY ts;

SELECT ts FROM json2_add_column WHERE trace_ctx.trace_id = 't-5';

-- Invalid JSON2 settings are rejected without changing the table.
ALTER TABLE json2_add_column ADD COLUMN bad JSON2 (a STRING, a BIGINT);

ALTER TABLE json2_add_column ADD COLUMN bad JSON2 (a INT8);

-- Plain columns still go through the usual path, also mixed with JSON2 ones.
ALTER TABLE json2_add_column
    ADD COLUMN zone STRING DEFAULT 'z1' COMMENT 'zone' FIRST,
    ADD COLUMN extra JSON2 (k STRING) AFTER host;

DESC TABLE json2_add_column;

SELECT ts, zone, extra.k FROM json2_add_column WHERE ts <= 2 ORDER BY ts;

DROP TABLE json2_add_column;

CREATE TABLE json2_add_column_non_append (
    ts TIMESTAMP TIME INDEX,
    v INT
);

-- JSON2 still requires append mode.
ALTER TABLE json2_add_column_non_append ADD COLUMN j JSON2 (a STRING);

DROP TABLE json2_add_column_non_append;
