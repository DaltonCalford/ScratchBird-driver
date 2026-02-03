-- ScratchBird-driver
-- Copyright (c) 2025-2026 Dalton Calford
--
-- Licensed under the Initial Developer's Public License Version 1.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at:
-- https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
-- ScratchBird driver conformance type fixture
-- Assumes core_fixture.sql has created base tables.

CREATE TABLE type_coverage (
    bool_val BOOLEAN,
    int16_val SMALLINT,
    int32_val INTEGER,
    int64_val BIGINT,
    float32_val REAL,
    float64_val DOUBLE PRECISION,
    decimal_val DECIMAL(10,2),
    numeric_val NUMERIC(12,4),
    money_val MONEY,
    char_val CHAR(4),
    varchar_val VARCHAR(20),
    text_val TEXT,
    bytea_val BYTEA,
    date_val DATE,
    time_val TIME,
    ts_val TIMESTAMP,
    tstz_val TIMESTAMP WITH TIME ZONE,
    interval_val INTERVAL,
    uuid_val UUID,
    json_val JSON,
    jsonb_val JSONB,
    xml_val XML,
    inet_val INET,
    cidr_val CIDR,
    macaddr_val MACADDR,
    array_val INTEGER[],
    vector_val VECTOR(3),
    tsvector_val TSVECTOR,
    tsquery_val TSQUERY
);

DELETE FROM type_coverage;

INSERT INTO type_coverage (
    bool_val,
    int16_val,
    int32_val,
    int64_val,
    float32_val,
    float64_val,
    decimal_val,
    numeric_val,
    money_val,
    char_val,
    varchar_val,
    text_val,
    bytea_val,
    date_val,
    time_val,
    ts_val,
    tstz_val,
    interval_val,
    uuid_val,
    json_val,
    jsonb_val,
    xml_val,
    inet_val,
    cidr_val,
    macaddr_val,
    array_val,
    vector_val,
    tsvector_val,
    tsquery_val
) VALUES (
    TRUE,
    32767,
    2147483647,
    9223372036854775807,
    3.14,
    2.718281828459045,
    12345.67,
    98765.4321,
    19.99,
    'ABCD',
    'varchar-value',
    'text-value',
    CAST('01020304' AS BYTEA),
    CAST('2026-01-09' AS DATE),
    CAST('12:34:56.789' AS TIME),
    CAST('2026-01-09 12:34:56.789' AS TIMESTAMP),
    CAST('2026-01-09 12:34:56.789+00:00' AS TIMESTAMP WITH TIME ZONE),
    CAST(NULL AS INTERVAL),
    CAST('00000000-0000-0000-0000-000000000002' AS UUID),
    CAST('{"k":"v"}' AS JSON),
    CAST('{"k":"v"}' AS JSONB),
    CAST('<root><a>1</a></root>' AS XML),
    CAST(NULL AS INET),
    CAST(NULL AS CIDR),
    CAST(NULL AS MACADDR),
    CAST(NULL AS INTEGER[]),
    CAST(NULL AS VECTOR(3)),
    CAST(NULL AS TSVECTOR),
    CAST(NULL AS TSQUERY)
);
