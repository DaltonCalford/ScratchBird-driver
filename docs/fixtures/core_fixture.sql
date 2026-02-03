-- ScratchBird-driver
-- Copyright (c) 2025-2026 Dalton Calford
--
-- Licensed under the Initial Developer's Public License Version 1.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at:
-- https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
-- ScratchBird driver conformance core fixture
-- Assumes a clean database or a dedicated test database.

CREATE TABLE basic_table (
    id UUID PRIMARY KEY,
    name VARCHAR(100),
    created_at TIMESTAMP,
    active BOOLEAN,
    amount DECIMAL(10,2)
);

DELETE FROM basic_table;

INSERT INTO basic_table (
    id, name, created_at, active, amount
) VALUES (
    CAST('00000000-0000-0000-0000-000000000001' AS UUID),
    'baseline',
    CAST('2026-01-09 12:34:56.789' AS TIMESTAMP),
    TRUE,
    123.45
);

INSERT INTO basic_table (
    id, name, created_at, active, amount
) VALUES (
    CAST('00000000-0000-0000-0000-000000000002' AS UUID), 'sample-02', CAST('2026-01-09 12:35:56.789' AS TIMESTAMP), FALSE, 10.00
);

INSERT INTO basic_table (
    id, name, created_at, active, amount
) VALUES (
    CAST('00000000-0000-0000-0000-000000000003' AS UUID), 'sample-03', CAST('2026-01-09 12:36:56.789' AS TIMESTAMP), TRUE, 20.00
);

INSERT INTO basic_table (
    id, name, created_at, active, amount
) VALUES (
    CAST('00000000-0000-0000-0000-000000000004' AS UUID), 'sample-04', CAST('2026-01-09 12:37:56.789' AS TIMESTAMP), TRUE, 30.00
);

INSERT INTO basic_table (
    id, name, created_at, active, amount
) VALUES (
    CAST('00000000-0000-0000-0000-000000000005' AS UUID), 'sample-05', CAST('2026-01-09 12:38:56.789' AS TIMESTAMP), FALSE, 40.00
);

INSERT INTO basic_table (
    id, name, created_at, active, amount
) VALUES (
    CAST('00000000-0000-0000-0000-000000000006' AS UUID), 'sample-06', CAST('2026-01-09 12:39:56.789' AS TIMESTAMP), TRUE, 50.00
);
