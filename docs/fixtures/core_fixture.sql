-- ScratchBird-driver
-- Copyright (c) 2025-2026 Dalton Calford
--
-- Licensed under the Initial Developer's Public License Version 1.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at:
-- https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
-- ScratchBird driver conformance core fixture
-- Assumes a clean database or a dedicated test database.

CREATE SCHEMA sb_conformance;

CREATE TABLE sb_conformance.basic_table (
    id UUID PRIMARY KEY,
    name VARCHAR(100),
    created_at TIMESTAMP,
    active BOOLEAN,
    amount DECIMAL(10,2)
);

INSERT INTO sb_conformance.basic_table (
    id, name, created_at, active, amount
) VALUES (
    '00000000-0000-0000-0000-000000000001'::UUID,
    'baseline',
    TIMESTAMP '2026-01-09 12:34:56.789',
    TRUE,
    123.45
);

INSERT INTO sb_conformance.basic_table (
    id, name, created_at, active, amount
) VALUES
    ('00000000-0000-0000-0000-000000000002'::UUID, 'sample-02', TIMESTAMP '2026-01-09 12:35:56.789', FALSE, 10.00),
    ('00000000-0000-0000-0000-000000000003'::UUID, 'sample-03', TIMESTAMP '2026-01-09 12:36:56.789', TRUE, 20.00),
    ('00000000-0000-0000-0000-000000000004'::UUID, 'sample-04', TIMESTAMP '2026-01-09 12:37:56.789', TRUE, 30.00),
    ('00000000-0000-0000-0000-000000000005'::UUID, 'sample-05', TIMESTAMP '2026-01-09 12:38:56.789', FALSE, 40.00),
    ('00000000-0000-0000-0000-000000000006'::UUID, 'sample-06', TIMESTAMP '2026-01-09 12:39:56.789', TRUE, 50.00);
