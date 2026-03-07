# Apache Superset Compatibility Specification

**Document Version:** 1.0
**Created:** 2026-01-29
**Status:** Draft - Implementation Ready
**Scope:** Requirements to support Apache Superset connectivity with ScratchBird (native SBWP v1.1)

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Superset Overview](#2-superset-overview)
3. [Driver Architecture](#3-driver-architecture)
4. [Core Driver Capabilities](#4-core-driver-capabilities)
5. [Connection Details Schema](#5-connection-details-schema)
6. [Schema Introspection Requirements](#6-schema-introspection-requirements)
7. [Data Type Mapping](#7-data-type-mapping)
8. [SQL Query Requirements](#8-sql-query-requirements)
9. [Feature Flags / Capabilities](#9-feature-flags--capabilities)
10. [Authentication & Security](#10-authentication--security)
11. [Error Handling](#11-error-handling)
12. [Implementation Plan](#12-implementation-plan)
13. [Testing Requirements](#13-testing-requirements)
14. [References](#14-references)

---

## 1. Executive Summary

- **Recommended Approach:** SQLAlchemy dialect + Superset DB engine spec, backed by the ScratchBird Python DB-API driver.
- **Alternative Approach:** PostgreSQL emulation listener + Superset Postgres dialect (limited, emulation-only).
- **Critical Dependencies:** ScratchBird DB-API driver, SQLAlchemy dialect, Superset EngineSpec entry point.
- **Estimated Complexity:** Medium (custom package, no Superset code changes required).

---

## 2. Superset Overview

Superset is a Python-based analytics and visualization platform. It uses:

- **DB-API 2.0 drivers** for connectivity.
- **SQLAlchemy dialects** to build SQL and fetch metadata.
- **DB engine specs** to customize database behavior and feature flags.

ScratchBird must provide a DB-API driver and an SQLAlchemy dialect. A
Superset DB engine spec is optional but strongly recommended to provide
correct time grain expressions, capability flags, and metadata behaviors.

---

## 3. Driver Architecture

### 3.1 Target Integration

**ScratchBird Superset Driver** package provides:

1. **SQLAlchemy dialect** (`scratchbird://`) backed by ScratchBird Python driver.
2. **Superset DB engine spec** registered via entry point `superset.db_engine_specs`.

### 3.2 Packaging Format

- Python package `scratchbird-superset`.
- Entry points:
  - `sqlalchemy.dialects`: `scratchbird = scratchbird_superset.dialect:ScratchBirdDialect`
  - `superset.db_engine_specs`: `scratchbird = scratchbird_superset.engine_spec:ScratchBirdEngineSpec`

### 3.3 Runtime Requirements

- Python 3.9+
- SQLAlchemy >= 1.4
- ScratchBird Python DB-API driver (`scratchbird`)
- Apache Superset runtime (already present in the Superset environment)

---

## 4. Core Driver Capabilities

Minimum required behaviors:

- Connection test and validation
- Query execution + streaming result sets
- Prepared statements + bind parameters via the ScratchBird Python driver
- Result metadata (column names/types)
- Schema discovery (schemas, tables, columns)
- Cancel support (ScratchBird `Connection.cancel()`)

---

## 5. Connection Details Schema

Superset connections use a SQLAlchemy URI and optional query parameters.

**Base URI format:**
```
scratchbird://{user}:{password}@{host}:{port}/{database}
```

**Supported query params:**
- sslmode (disable | allow | prefer | require | verify-ca | verify-full)
- sslrootcert
- sslcert
- sslkey
- application_name
- connect_timeout
- socket_timeout
- binary_transfer (true/false)
- compression (off | zstd)
- front_door_mode
- manager_auth_token

**Example:**
```
scratchbird://admin:secret@db01:3092/analytics?sslmode=prefer&compression=zstd
```

---

## 6. Schema Introspection Requirements

Superset uses SQLAlchemy `Inspector` to enumerate metadata. ScratchBird
must support metadata queries via `sys.*` views as defined in
`docs/specifications/METADATA_SCHEMA_CONTRACT.md`.

**Required queries (baseline):**
- Schemas: `sys.schemas`
- Tables: `sys.tables`
- Columns: `sys.columns`
- Indexes: `sys.indexes`
- Constraints: `sys.constraints`

**Dialect implementation:**
- Implement `get_schema_names`, `get_table_names`, `get_view_names`, `get_columns`.
- Optional: `get_indexes`, `get_pk_constraint`, `get_foreign_keys`.

If `sys.types` is available, map `data_type_id` to human-readable type names.
If not, return a safe default (STRING) and log the gap for remediation.

---

## 7. Data Type Mapping

ScratchBird types should map to SQLAlchemy types. Use the driver-wide
`TYPE_MAPPING_MATRIX.md` as the canonical reference.

| ScratchBird Type | SQLAlchemy Type | Notes |
|---|---|---|
| BOOLEAN | Boolean | |
| SMALLINT | SmallInteger | |
| INTEGER | Integer | |
| BIGINT | BigInteger | |
| REAL/FLOAT/DOUBLE | Float | |
| NUMERIC/DECIMAL | Numeric | |
| CHAR/VARCHAR/TEXT | String/Text | |
| DATE | Date | |
| TIME | Time | |
| TIMESTAMP | DateTime | |
| TIMESTAMPTZ | DateTime(timezone=True) | |
| UUID | Uuid | |
| JSON/JSONB | JSON | Wrapper types supported via driver |
| BYTEA/BLOB | LargeBinary | |

---

## 8. SQL Query Requirements

Superset’s query builder uses:

- SELECT / WHERE / GROUP BY / ORDER BY / HAVING
- JOINs and subqueries
- LIMIT / OFFSET
- Aggregations: COUNT, SUM, AVG, MIN, MAX
- Window functions: ROW_NUMBER, LAG/LEAD (where supported)
- Date/time grains using `DATE_TRUNC` or equivalent

ScratchBird must support these for full Superset parity.

---

## 9. Feature Flags / Capabilities

EngineSpec should declare the following (target state):

- allows_joins = true
- allows_subqueries = true
- allows_alias_in_select = true
- allows_alias_in_orderby = true
- supports_dynamic_schema = true
- supports_catalog = true
- limit_method = FORCE_LIMIT

Optional flags once supported:
- supports_file_upload
- supports_time_grain_expressions (full coverage)

---

## 10. Authentication & Security

- TLS-enabled modes should be the default for production deployments.
- `sslmode=disable` is available for explicit local-development/plaintext paths
  in the current Python driver lane.
- Support SCRAM (SBWP v1.1) authentication via ScratchBird Python driver.
- Support manager-proxy and auth-plugin-aware startup parameters when the
  Superset connection URI includes them.

---

## 11. Error Handling

- Map ScratchBird DB-API errors to Superset error categories.
- Prefer SQLSTATE mapping where available (see `DRIVER_ERROR_MAPPING.md`).

---

## 12. Implementation Plan

**Phase 1: SQLAlchemy dialect**
- Create `scratchbird_superset.dialect` package.
- Implement connection arg mapping + schema/table/column reflection.

**Phase 2: EngineSpec integration**
- Provide `ScratchBirdEngineSpec` with metadata and time grains.
- Register entry points for Superset discovery.

**Phase 3: Superset validation**
- Validate database registration, schema sync, and SQL Lab queries.
- Validate metadata scanning and query execution in dashboards.

---

## 13. Testing Requirements

- Unit tests: DSN parsing and SQLAlchemy connect args.
- Integration tests (env-gated):
  - `SCRATCHBIRD_TEST_DSN` for SQLAlchemy connection
  - `SCRATCHBIRD_SUPERSET_DSN` for Superset metadata sync

---

## 14. References

- Superset database drivers overview: https://superset.apache.org/docs/databases/
- Superset DB engine spec README: https://github.com/apache/superset/blob/master/superset/db_engine_specs/README.md
- Superset engine spec entry points: https://github.com/apache/superset/blob/master/superset/db_engine_specs/__init__.py
- SQLAlchemy dialect docs: https://docs.sqlalchemy.org/en/20/dialects/
- ScratchBird metadata contract: `docs/specifications/METADATA_SCHEMA_CONTRACT.md`
