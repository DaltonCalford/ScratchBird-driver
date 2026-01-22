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

