# Metabase Business Intelligence Compatibility Specification

**Document Version:** 1.1
**Created:** January 2026
**Status:** Draft - Implementation Ready
**Scope:** Requirements to build a Metabase driver that targets ScratchBird (native SBWP v1.1)

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Metabase Overview](#2-metabase-overview)
3. [Driver Architecture](#3-driver-architecture)
    - [Target Implementation (ScratchBird JDBC Plugin)](#34-target-implementation-scratchbird-jdbc-plugin)
4. [Core Driver Capabilities](#4-core-driver-capabilities)
    - [Connection Details Schema](#42-connection-details-schema)
5. [Schema Introspection Requirements](#5-schema-introspection-requirements)
6. [Data Type Mapping](#6-data-type-mapping)
7. [SQL Query Requirements](#7-sql-query-requirements)
8. [Driver Feature Flags](#8-driver-feature-flags)
9. [Semantic Types](#9-semantic-types)
10. [Implementation Strategies](#10-implementation-strategies)
11. [PostgreSQL Compatibility Path](#11-postgresql-compatibility-path)
12. [JDBC Driver Requirements](#12-jdbc-driver-requirements)
13. [Minimum Viable Implementation](#13-minimum-viable-implementation)
14. [Testing Requirements](#14-testing-requirements)
15. [References](#15-references)

---

## 1. Executive Summary

Metabase is an open-source business intelligence (BI) tool that enables users to ask questions about their data and visualize results through dashboards and reports. This specification documents the requirements for ScratchBird to support Metabase connectivity.

### Key Findings

| Aspect | Requirement |
|--------|-------------|
| **Recommended Approach** | Metabase plugin + ScratchBird JDBC driver (SBWP v1.1, native port 3092) |
| **Alternative Approach** | PostgreSQL compatibility listener + Metabase PostgreSQL driver |
| **Critical Dependencies** | ScratchBird JDBC driver metadata + catalog view coverage |
| **Estimated Complexity** | Medium (custom plugin) / Medium (PostgreSQL path) |

### Implementation Priority

1. **Phase 1:** Build a Metabase driver plugin that uses the ScratchBird JDBC driver
2. **Phase 2:** Validate Metabase sync/scan queries and query builder output
3. **Phase 3:** Confirm dashboards, alerts, and scheduled queries
4. **Phase 4 (Optional):** PostgreSQL compatibility path (no plugin) for fallback

---

## 2. Metabase Overview

### 2.1 What is Metabase?

Metabase is a self-service BI tool that allows non-technical users to explore data through:

- **Visual Query Builder:** Point-and-click interface for building queries
- **SQL Editor:** Direct SQL query execution for advanced users
- **Dashboards:** Collections of visualizations and metrics
- **Alerts:** Automated notifications based on data conditions
- **Embedding:** White-label embedding in other applications

### 2.2 Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Metabase Server                          │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │   Web UI    │  │  Query      │  │    Driver Plugin        │  │
│  │  (React)    │  │  Processor  │  │    System               │  │
│  └──────┬──────┘  └──────┬──────┘  └───────────┬─────────────┘  │
│         │                │                     │                │
│         ▼                ▼                     ▼                │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                    MBQL (Metabase Query Language)           ││
│  └─────────────────────────────────────────────────────────────┘│
│                              │                                  │
│                              ▼                                  │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                    Driver Interface                         ││
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────────────┐   ││
│  │  │PostgreSQL│ │ MySQL  │ │ Oracle │ │ ScratchBird     │   ││
│  │  │ Driver  │ │ Driver │ │ Driver │ │ (via PG compat) │   ││
│  │  └────┬────┘ └────┬────┘ └────┬────┘ └────────┬────────┘   ││
│  └───────┼───────────┼───────────┼───────────────┼─────────────┘│
└──────────┼───────────┼───────────┼───────────────┼──────────────┘
           │           │           │               │
           ▼           ▼           ▼               ▼
      ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────────────┐
      │PostgreSQL│ │  MySQL │ │ Oracle │ │   ScratchBird   │
      │   DB    │ │   DB   │ │   DB   │ │   (Port 3092)   │
      └─────────┘ └─────────┘ └─────────┘ └─────────────────┘
```

### 2.3 System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| CPU | 1 core | 1 core per 20 concurrent users |
| RAM | 1 GB | 2 GB per 20 concurrent users |
| Java | Java 11 | Java 17+ |
| Application DB | H2 (dev only) | PostgreSQL 12+ or MySQL 8+ |

---

## 3. Driver Architecture

### 3.1 Plugin System

Metabase drivers are packaged as JAR plugins containing:

```
my-driver.jar
├── metabase-plugin.yaml          # Plugin manifest
├── deps.edn                      # Dependencies
└── src/
    └── metabase/
        └── driver/
            └── my_driver.clj     # Driver implementation
```

### 3.2 Driver Hierarchy

Metabase uses Clojure multimethods with inheritance:

```
                    :driver (base)
                        │
            ┌───────────┼───────────┐
            │           │           │
          :sql      :mongo      :sparksql
            │
      ┌─────┴─────┐
      │           │
  :sql-jdbc    :bigquery
      │
  ┌───┴───┬───────┬───────┬───────┐
  │       │       │       │       │
:postgres :mysql :oracle :h2  :scratchbird
      │                           (potential)
  :redshift
```

### 3.3 Parent Driver Benefits

Using `:sql-jdbc` as parent provides:

| Feature | Implementation Status |
|---------|----------------------|
| Connection pooling | Provided |
| Query execution | Provided |
| Result set handling | Provided |
| Basic type mapping | Provided |
| Sync infrastructure | Provided |
| MBQL to SQL translation | Mostly provided |

**Child driver responsibilities:**
- Connection string building
- Database-specific type mapping
- Custom SQL syntax handling
- Feature flag declarations

### 3.4 Target Implementation (ScratchBird JDBC Plugin)

**Goal:** A Metabase plugin that exposes a `:scratchbird` driver and uses the
ScratchBird JDBC driver (SBWP v1.1) for connectivity.

**Driver identity:**
- Driver name: `scratchbird`
- Parent: `sql-jdbc`
- JDBC class: `com.scratchbird.jdbc.SBDriver`
- Default port: `3092`

**Plugin layout (minimum):**
```
scratchbird-metabase-driver/
├── metabase-plugin.yaml
├── deps.edn
└── src/
    └── metabase/
        └── driver/
            └── scratchbird.clj
```

**metabase-plugin.yaml (example):**
```yaml
info:
  name: ScratchBird
  version: 0.1.0
  description: ScratchBird JDBC driver for Metabase
driver:
  name: scratchbird
  init: metabase.driver.scratchbird/init
  parent: sql-jdbc
```

**deps.edn (example):**
```clojure
{:paths ["src" "resources"]
 :deps {org.clojure/clojure {:mvn/version "1.11.1"}
        com.scratchbird/scratchbird-jdbc {:mvn/version "0.1.0"}}}
```

If the ScratchBird JDBC driver is not published to Maven yet, bundle the JAR
inside the plugin and add it to the classpath during build.

**Driver namespace skeleton (scratchbird.clj):**
```clojure
(ns metabase.driver.scratchbird
  (:require [metabase.driver :as driver]
            [metabase.driver.sql-jdbc :as sql-jdbc]
            [metabase.driver.sql-jdbc.connection :as sql-jdbc.conn]))

(defmethod driver/display-name :scratchbird [_] "ScratchBird")

(defmethod driver/connection-properties :scratchbird
  [_]
  [{:name "host" :display-name "Host" :type :string :default "localhost" :required true}
   {:name "port" :display-name "Port" :type :integer :default 3092 :required true}
   {:name "db" :display-name "Database" :type :string :required true}
   {:name "user" :display-name "Username" :type :string :required true}
   {:name "password" :display-name "Password" :type :password :required true}
   {:name "sslmode" :display-name "SSL Mode" :type :select
    :options [{:name "require"} {:name "verify-ca"} {:name "verify-full"}]
    :default "require"}
   {:name "sslrootcert" :display-name "CA Certificate" :type :string}
   {:name "sslcert" :display-name "Client Certificate" :type :string}
   {:name "sslkey" :display-name "Client Key" :type :string}
   {:name "application_name" :display-name "Application Name" :type :string :default "metabase"}])

(defmethod driver/connection-details->spec :scratchbird
  [_ details]
  (sql-jdbc.conn/connection-details->spec
   details
   {:classname "com.scratchbird.jdbc.SBDriver"
    :subprotocol "scratchbird"
    :subname (format "//%s:%s/%s"
                     (:host details) (:port details) (:db details))}))

(defmethod driver/db-default-timezone :scratchbird [_ _] "UTC")

(defmethod driver/database-supports? [:scratchbird :schemas] [_ _ _] true)
(defmethod driver/database-supports? [:scratchbird :foreign-keys] [_ _ _] true)
(defmethod driver/database-supports? [:scratchbird :basic-aggregations] [_ _ _] true)
```

**Compatibility goal:** Keep the driver thin. Favor `sql-jdbc` defaults unless
ScratchBird requires overrides for quoting, identifier casing, or date functions.

**Packaging notes:**
- The plugin must be a single JAR placed in `MB_PLUGINS_DIR`.
- The JAR must include the ScratchBird JDBC driver classes or reference them
  via classpath.
- Restart Metabase after updating the plugin JAR.

---

## 4. Core Driver Capabilities

### 4.1 Four Main Features

Every Metabase driver MUST implement these four capabilities:

#### 4.1.1 Connection & Database Information

**Purpose:** Validate connectivity and provide database metadata.

**Required Methods:**

| Method | Description | Priority |
|--------|-------------|----------|
| `can-connect?` | Test if connection parameters are valid | REQUIRED |
| `db-default-timezone` | Return database timezone | REQUIRED |
| `db-start-of-week` | Return week start day (`:sunday` or `:monday`) | Optional |
| `display-name` | Human-readable driver name | REQUIRED |

**Example Implementation:**
```clojure
(defmethod driver/can-connect? :scratchbird
  [_ details]
  (let [conn (connect details)]
    (try
      (.isValid conn 5)
      (finally (.close conn)))))

(defmethod driver/display-name :scratchbird
  [_]
  "ScratchBird")
```

#### 4.1.2 Schema Introspection (Sync)

**Purpose:** Discover database structure for the visual query builder.

**Required Methods:**

| Method | Description | Priority |
|--------|-------------|----------|
| `describe-database` | Return set of tables/schemas | REQUIRED |
| `describe-table` | Return fields for a table | REQUIRED |
| `describe-table-fks` | Return foreign key relationships | Recommended |
| `describe-table-indexes` | Return index information | Optional |

**Data Structures:**

```clojure
;; describe-database returns:
{:tables #{{:name "users" :schema "public"}
           {:name "orders" :schema "public"}}}

;; describe-table returns:
{:name "users"
 :schema "public"
 :fields #{{:name "id"
            :database-type "INTEGER"
            :base-type :type/Integer
            :pk? true}
           {:name "email"
            :database-type "VARCHAR(255)"
            :base-type :type/Text}}}

;; describe-table-fks returns:
#{{:fk-column-name "user_id"
   :dest-table {:name "users" :schema "public"}
   :dest-column-name "id"}}
```

#### 4.1.3 Query Translation (MBQL to SQL)

**Purpose:** Convert Metabase's internal query language to native SQL.

**MBQL Example:**
```clojure
{:source-table 1
 :aggregation [[:count]]
 :breakout [[:field 5 nil]]
 :filter [:= [:field 3 nil] "active"]}
```

**Translated SQL:**
```sql
SELECT status, COUNT(*)
FROM users
WHERE status = 'active'
GROUP BY status
```

**Key Translation Methods:**

| Method | Description |
|--------|-------------|
| `sql.qp/->honeysql` | Convert MBQL clause to HoneySQL |
| `sql.qp/date` | Date truncation/extraction |
| `sql.qp/current-datetime-honeysql-form` | Current timestamp expression |
| `sql.qp/unix-timestamp->honeysql` | Unix timestamp conversion |

#### 4.1.4 Query Execution

**Purpose:** Execute queries and return results.

**Required Methods:**

| Method | Description | Priority |
|--------|-------------|----------|
| `execute-reducible-query` | Execute query, return reducible results | REQUIRED |
| `connection-details->spec` | Build JDBC connection spec | REQUIRED (JDBC) |

**Result Format:**
```clojure
{:cols [{:name "status" :base_type :type/Text}
        {:name "count" :base_type :type/Integer}]
 :rows [["active" 150]
        ["inactive" 45]]}
```

### 4.2 Connection Details Schema

The Metabase UI uses the connection property schema defined by the driver.
The ScratchBird driver must expose these fields and map them into the JDBC URL
and connection properties.

**Required fields:**
- host (string, default `localhost`)
- port (integer, default `3092`)
- db (string, required)
- user (string, required)
- password (password, required)
- sslmode (select: `require`, `verify-ca`, `verify-full`; default `require`)
- sslrootcert (string, optional)
- sslcert (string, optional)
- sslkey (string, optional)
- sslpassword (password, optional)
- role (string, optional)
- application_name (string, default `metabase`)
- connectTimeout (integer seconds, optional)
- socketTimeout (integer seconds, optional)
- binaryTransfer (boolean, default `true`)

**JDBC URL template:**
```
jdbc:scratchbird://{host}:{port}/{db}?sslmode={sslmode}&application_name={application_name}
```

**Property mapping:**
- `sslmode` -> JDBC property `sslmode`
- `sslrootcert` -> JDBC property `sslrootcert`
- `sslcert` -> JDBC property `sslcert`
- `sslkey` -> JDBC property `sslkey`
- `sslpassword` -> JDBC property `sslpassword`
- `role` -> JDBC property `role`
- `connectTimeout` -> JDBC property `connectTimeout`
- `socketTimeout` -> JDBC property `socketTimeout`
- `binaryTransfer` -> JDBC property `binaryTransfer`

**TLS requirement:** ScratchBird requires TLS. Metabase should reject
`sslmode=disable` at validation time.

---

## 5. Schema Introspection Requirements

### 5.1 Sync Process Overview

Metabase performs two types of database analysis:

| Process | Frequency | Purpose |
|---------|-----------|---------|
| **Sync** | Hourly (default) | Discover schema structure |
| **Scan** | Daily (default) | Sample data for fingerprinting |

### 5.2 Sync Queries

Metabase executes these queries during sync:

#### 5.2.1 Schema Discovery

```sql
-- PostgreSQL style
SELECT nspname AS schema_name
FROM pg_namespace
WHERE nspname NOT IN ('pg_catalog', 'information_schema', 'pg_toast')
  AND nspname NOT LIKE 'pg_temp_%'
  AND nspname NOT LIKE 'pg_toast_temp_%';

-- Or via information_schema
SELECT schema_name
FROM information_schema.schemata
WHERE schema_name NOT IN ('pg_catalog', 'information_schema');
```

#### 5.2.2 Table Discovery

```sql
-- PostgreSQL style
SELECT c.relname AS table_name,
       n.nspname AS schema_name,
       c.relkind AS table_type
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind IN ('r', 'v', 'm', 'f', 'p')  -- tables, views, materialized views, foreign tables, partitioned
  AND n.nspname NOT IN ('pg_catalog', 'information_schema');

-- Or via information_schema
SELECT table_name, table_schema, table_type
FROM information_schema.tables
WHERE table_schema NOT IN ('pg_catalog', 'information_schema');
```

#### 5.2.3 Column Discovery

```sql
-- PostgreSQL style
SELECT a.attname AS column_name,
       pg_catalog.format_type(a.atttypid, a.atttypmod) AS data_type,
       a.attnotnull AS not_null,
       a.attnum AS ordinal_position
FROM pg_attribute a
JOIN pg_class c ON c.oid = a.attrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE a.attnum > 0
  AND NOT a.attisdropped
  AND c.relname = 'table_name'
  AND n.nspname = 'schema_name';

-- Or via information_schema
SELECT column_name, data_type, is_nullable, ordinal_position,
       column_default, character_maximum_length, numeric_precision
FROM information_schema.columns
WHERE table_schema = 'schema_name'
  AND table_name = 'table_name'
ORDER BY ordinal_position;
```

#### 5.2.4 Primary Key Discovery

```sql
-- PostgreSQL style
SELECT a.attname AS column_name
FROM pg_index i
JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY(i.indkey)
WHERE i.indrelid = 'schema_name.table_name'::regclass
  AND i.indisprimary;

-- Or via information_schema
SELECT kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_schema = 'schema_name'
  AND tc.table_name = 'table_name'
  AND tc.constraint_type = 'PRIMARY KEY';
```

#### 5.2.5 Foreign Key Discovery

```sql
-- PostgreSQL style
SELECT
    kcu.column_name AS fk_column,
    ccu.table_schema AS ref_schema,
    ccu.table_name AS ref_table,
    ccu.column_name AS ref_column
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'schema_name'
  AND tc.table_name = 'table_name';
```

#### 5.2.6 Table Existence Check

```sql
-- Used to verify table exists before querying
SELECT TRUE FROM "schema_name"."table_name" WHERE 1 <> 1 LIMIT 0;
```

### 5.3 Scan Queries (Fingerprinting)

```sql
-- Initial fingerprint sample
SELECT * FROM "schema_name"."table_name" LIMIT 10000;

-- Distinct value sampling for filters
SELECT DISTINCT "column_name"
FROM "schema_name"."table_name"
LIMIT 1000;
```

### 5.4 Required PostgreSQL System Catalog Views

For PostgreSQL compatibility mode, ScratchBird MUST implement:

| Catalog Object | Purpose |
|----------------|---------|
| `pg_namespace` | Schema information |
| `pg_class` | Tables, views, indexes, sequences |
| `pg_attribute` | Column information |
| `pg_type` | Data type definitions |
| `pg_constraint` | Constraints (PK, FK, CHECK, UNIQUE) |
| `pg_index` | Index metadata |
| `pg_description` | Object comments |
| `pg_am` | Access methods |
| `pg_proc` | Functions/procedures |
| `pg_roles` | Role information |

| Information Schema View | Purpose |
|------------------------|---------|
| `information_schema.schemata` | Schema listing |
| `information_schema.tables` | Table listing |
| `information_schema.columns` | Column metadata |
| `information_schema.table_constraints` | Constraint metadata |
| `information_schema.key_column_usage` | Key column details |
| `information_schema.constraint_column_usage` | Constraint columns |
| `information_schema.referential_constraints` | FK details |

---

## 6. Data Type Mapping

### 6.1 Metabase Base Types

Map database types to Metabase's internal type hierarchy:

| Metabase Base Type | SQL Types | Notes |
|--------------------|-----------|-------|
| `:type/Text` | TEXT, CHAR, VARCHAR, CLOB, CHARACTER VARYING | String data |
| `:type/Integer` | INTEGER, INT, INT4, SMALLINT, INT2, BIGINT, INT8 | Whole numbers |
| `:type/Float` | FLOAT, FLOAT4, FLOAT8, REAL, DOUBLE PRECISION | Floating point |
| `:type/Decimal` | DECIMAL, NUMERIC, NUMBER | Exact decimals |
| `:type/Boolean` | BOOLEAN, BOOL | True/false |
| `:type/Date` | DATE | Date only |
| `:type/Time` | TIME, TIME WITHOUT TIME ZONE | Time only |
| `:type/TimeWithTZ` | TIME WITH TIME ZONE, TIMETZ | Time with timezone |
| `:type/DateTime` | TIMESTAMP, TIMESTAMP WITHOUT TIME ZONE | Date and time |
| `:type/DateTimeWithTZ` | TIMESTAMP WITH TIME ZONE, TIMESTAMPTZ | Timestamp with TZ |
| `:type/UUID` | UUID | Unique identifiers |
| `:type/JSON` | JSON, JSONB | JSON data |
| `:type/Array` | ARRAY, anyarray | Array types (limited support) |
| `:type/IPAddress` | INET, CIDR | Network addresses |
| `:type/Structured` | RECORD, ROW | Composite types |
| `:type/* ` | (fallback) | Unknown types |

### 6.2 ScratchBird Type Mapping

Based on ScratchBird's 86 data types, map to Metabase:

```clojure
(def scratchbird-type->base-type
  {"BOOLEAN"                :type/Boolean
   "SMALLINT"               :type/Integer
   "INTEGER"                :type/Integer
   "BIGINT"                 :type/BigInteger
   "REAL"                   :type/Float
   "DOUBLE PRECISION"       :type/Float
   "NUMERIC"                :type/Decimal
   "DECIMAL"                :type/Decimal
   "CHAR"                   :type/Text
   "VARCHAR"                :type/Text
   "TEXT"                   :type/Text
   "CLOB"                   :type/Text
   "DATE"                   :type/Date
   "TIME"                   :type/Time
   "TIME WITH TIME ZONE"    :type/TimeWithTZ
   "TIMESTAMP"              :type/DateTime
   "TIMESTAMP WITH TIME ZONE" :type/DateTimeWithTZ
   "UUID"                   :type/UUID
   "JSON"                   :type/JSON
   "JSONB"                  :type/JSON
   "BLOB"                   :type/*
   "BYTEA"                  :type/*
   "ARRAY"                  :type/Array
   "VECTOR"                 :type/Array
   "GEOMETRY"               :type/*
   "GEOGRAPHY"              :type/*
   "RECORD"                 :type/Structured
   "VARIANT"                :type/JSON
   "INET"                   :type/IPAddress
   "CIDR"                   :type/IPAddress
   "MACADDR"                :type/Text
   "BIT"                    :type/*
   "BIT VARYING"            :type/*
   "XML"                    :type/Text
   "INTERVAL"               :type/*
   "MONEY"                  :type/Decimal
   "SERIAL"                 :type/Integer
   "BIGSERIAL"              :type/BigInteger})
```

### 6.3 PostgreSQL OID Mapping

For PostgreSQL wire protocol compatibility:

| Type OID | Type Name | Metabase Type |
|----------|-----------|---------------|
| 16 | bool | :type/Boolean |
| 20 | int8 | :type/BigInteger |
| 21 | int2 | :type/Integer |
| 23 | int4 | :type/Integer |
| 25 | text | :type/Text |
| 700 | float4 | :type/Float |
| 701 | float8 | :type/Float |
| 1043 | varchar | :type/Text |
| 1082 | date | :type/Date |
| 1083 | time | :type/Time |
| 1114 | timestamp | :type/DateTime |
| 1184 | timestamptz | :type/DateTimeWithTZ |
| 1700 | numeric | :type/Decimal |
| 2950 | uuid | :type/UUID |
| 114 | json | :type/JSON |
| 3802 | jsonb | :type/JSON |

---

## 7. SQL Query Requirements

### 7.1 Required SQL Features

#### 7.1.1 Basic DML (MUST Support)

| Feature | Example | Notes |
|---------|---------|-------|
| SELECT | `SELECT col1, col2 FROM table` | Basic projection |
| Column aliases | `SELECT col AS alias` | Required for query builder |
| Table aliases | `FROM table t` | Required for joins |
| WHERE | `WHERE col = value` | Basic filtering |
| AND/OR | `WHERE a AND (b OR c)` | Compound conditions |
| Comparison operators | `=, <>, <, >, <=, >=` | Standard comparisons |
| NULL handling | `IS NULL, IS NOT NULL` | NULL checks |
| LIKE | `LIKE '%pattern%'` | Pattern matching |
| IN | `IN (1, 2, 3)` | Set membership |
| BETWEEN | `BETWEEN a AND b` | Range checks |
| ORDER BY | `ORDER BY col ASC/DESC` | Sorting |
| LIMIT | `LIMIT n` | Result limiting |
| OFFSET | `OFFSET n` | Pagination |
| DISTINCT | `SELECT DISTINCT col` | Deduplication |

#### 7.1.2 Aggregations (MUST Support)

| Function | Example | Notes |
|----------|---------|-------|
| COUNT | `COUNT(*)`, `COUNT(col)`, `COUNT(DISTINCT col)` | Row counting |
| SUM | `SUM(col)` | Numeric sum |
| AVG | `AVG(col)` | Average |
| MIN | `MIN(col)` | Minimum value |
| MAX | `MAX(col)` | Maximum value |
| GROUP BY | `GROUP BY col1, col2` | Grouping |
| HAVING | `HAVING COUNT(*) > 5` | Group filtering |

#### 7.1.3 Joins (MUST Support)

| Join Type | Example |
|-----------|---------|
| INNER JOIN | `FROM a INNER JOIN b ON a.id = b.a_id` |
| LEFT JOIN | `FROM a LEFT JOIN b ON a.id = b.a_id` |
| RIGHT JOIN | `FROM a RIGHT JOIN b ON a.id = b.a_id` |
| FULL OUTER JOIN | `FROM a FULL OUTER JOIN b ON a.id = b.a_id` |
| CROSS JOIN | `FROM a CROSS JOIN b` |

#### 7.1.4 Subqueries (MUST Support)

```sql
-- Scalar subquery
SELECT (SELECT MAX(price) FROM products) AS max_price;

-- Table subquery
SELECT * FROM (SELECT * FROM orders WHERE status = 'active') sub;

-- IN subquery
SELECT * FROM users WHERE id IN (SELECT user_id FROM orders);

-- EXISTS subquery
SELECT * FROM users u WHERE EXISTS (SELECT 1 FROM orders o WHERE o.user_id = u.id);
```

### 7.2 Date/Time Functions (SHOULD Support)

| Function | PostgreSQL Syntax | Purpose |
|----------|-------------------|---------|
| Date truncation | `DATE_TRUNC('month', col)` | Truncate to unit |
| Extract | `EXTRACT(YEAR FROM col)` | Extract component |
| Current date | `CURRENT_DATE` | Today's date |
| Current timestamp | `CURRENT_TIMESTAMP`, `NOW()` | Current time |
| Date arithmetic | `col + INTERVAL '1 day'` | Add/subtract |
| Date difference | `col1 - col2` | Difference |
| Age | `AGE(col1, col2)` | Interval between |

**Date Truncation Units:**

| Unit | Example Output |
|------|----------------|
| `second` | `2026-01-22 14:30:45` |
| `minute` | `2026-01-22 14:30:00` |
| `hour` | `2026-01-22 14:00:00` |
| `day` | `2026-01-22 00:00:00` |
| `week` | `2026-01-20 00:00:00` (Monday) |
| `month` | `2026-01-01 00:00:00` |
| `quarter` | `2026-01-01 00:00:00` |
| `year` | `2026-01-01 00:00:00` |

### 7.3 String Functions (SHOULD Support)

| Function | Syntax | Purpose |
|----------|--------|---------|
| Concatenation | `col1 \|\| col2`, `CONCAT(a, b)` | Join strings |
| Substring | `SUBSTRING(col FROM start FOR len)` | Extract portion |
| Length | `LENGTH(col)`, `CHAR_LENGTH(col)` | String length |
| Upper/Lower | `UPPER(col)`, `LOWER(col)` | Case conversion |
| Trim | `TRIM(col)`, `LTRIM()`, `RTRIM()` | Remove whitespace |
| Replace | `REPLACE(col, 'old', 'new')` | String replacement |
| Position | `POSITION('sub' IN col)` | Find substring |
| Split | `SPLIT_PART(col, ',', 1)` | Split by delimiter |
| Regex match | `col ~ 'pattern'` | Pattern matching |
| Regex extract | `REGEXP_MATCHES(col, 'pattern')` | Extract matches |

### 7.4 Numeric Functions (SHOULD Support)

| Function | Syntax | Purpose |
|----------|--------|---------|
| Absolute | `ABS(col)` | Absolute value |
| Round | `ROUND(col, decimals)` | Rounding |
| Ceiling | `CEIL(col)` | Round up |
| Floor | `FLOOR(col)` | Round down |
| Power | `POWER(base, exp)` | Exponentiation |
| Square root | `SQRT(col)` | Square root |
| Logarithm | `LOG(col)`, `LN(col)` | Logarithms |
| Modulo | `MOD(a, b)`, `a % b` | Remainder |

### 7.5 Conditional Expressions (SHOULD Support)

```sql
-- CASE expression
CASE
    WHEN condition1 THEN result1
    WHEN condition2 THEN result2
    ELSE default_result
END

-- COALESCE
COALESCE(col1, col2, 'default')

-- NULLIF
NULLIF(col, 'value_to_null')

-- GREATEST / LEAST
GREATEST(col1, col2, col3)
LEAST(col1, col2, col3)
```

### 7.6 Window Functions (RECOMMENDED)

| Function | Example | Purpose |
|----------|---------|---------|
| ROW_NUMBER | `ROW_NUMBER() OVER (ORDER BY col)` | Sequential numbering |
| RANK | `RANK() OVER (ORDER BY col)` | Ranking with gaps |
| DENSE_RANK | `DENSE_RANK() OVER (ORDER BY col)` | Ranking without gaps |
| LAG | `LAG(col, 1) OVER (ORDER BY date)` | Previous row value |
| LEAD | `LEAD(col, 1) OVER (ORDER BY date)` | Next row value |
| SUM OVER | `SUM(col) OVER (PARTITION BY grp)` | Running sum |
| AVG OVER | `AVG(col) OVER (ROWS BETWEEN ...)` | Moving average |
| FIRST_VALUE | `FIRST_VALUE(col) OVER (...)` | First in window |
| LAST_VALUE | `LAST_VALUE(col) OVER (...)` | Last in window |
| NTILE | `NTILE(4) OVER (ORDER BY col)` | Quartile assignment |

**Window Frame Syntax:**
```sql
function() OVER (
    PARTITION BY partition_col
    ORDER BY order_col
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
)
```

### 7.7 Advanced Features (OPTIONAL)

| Feature | Example | Notes |
|---------|---------|-------|
| CTEs | `WITH cte AS (...) SELECT * FROM cte` | Readability |
| UNION/UNION ALL | `SELECT ... UNION ALL SELECT ...` | Combining results |
| INTERSECT | `SELECT ... INTERSECT SELECT ...` | Common rows |
| EXCEPT | `SELECT ... EXCEPT SELECT ...` | Difference |
| Recursive CTEs | `WITH RECURSIVE ...` | Hierarchical data |
| LATERAL joins | `FROM a, LATERAL (SELECT ... WHERE a.id = ...)` | Correlated subqueries |
| FILTER clause | `COUNT(*) FILTER (WHERE condition)` | Conditional aggregation |

---

## 8. Driver Feature Flags

### 8.1 Feature Declaration

Drivers declare capabilities via `database-supports?`:

```clojure
(defmethod driver/database-supports? [:scratchbird :feature-name]
  [_driver _feature _database]
  true)  ; or false
```

### 8.2 Essential Features

| Feature Flag | Description | ScratchBird Status |
|--------------|-------------|-------------------|
| `:foreign-keys` | FK relationships for joins | SUPPORTED |
| `:schemas` | Tables organized in schemas | SUPPORTED |
| `:basic-aggregations` | COUNT, SUM, AVG, MIN, MAX | SUPPORTED |
| `:standard-deviation-aggregations` | STDDEV, VARIANCE | SUPPORTED |
| `:expression-aggregations` | Expressions in aggregations | SUPPORTED |
| `:percentile-aggregations` | PERCENTILE_CONT, MEDIAN | SUPPORTED |

### 8.3 SQL Feature Flags

| Feature Flag | Description | ScratchBird Status |
|--------------|-------------|-------------------|
| `:expressions` | Custom expressions support | SUPPORTED |
| `:expressions/today` | `CURRENT_DATE` expression | SUPPORTED |
| `:expressions/datetime` | ISO string to datetime | SUPPORTED |
| `:expressions/date` | Text to date casting | SUPPORTED |
| `:expressions/integer` | Text to integer casting | SUPPORTED |
| `:expressions/float` | Text to float casting | SUPPORTED |
| `:expressions/text` | Value to text casting | SUPPORTED |
| `:split-part` | `SPLIT_PART` function | SUPPORTED |
| `:regex` | Basic regex support | SUPPORTED |
| `:regex/lookaheads-and-lookbehinds` | Advanced regex | TBD |
| `:collate` | Collation support | SUPPORTED |

### 8.4 Window Function Flags

| Feature Flag | Description | ScratchBird Status |
|--------------|-------------|-------------------|
| `:window-functions/cumulative` | CUM_SUM, CUM_COUNT | SUPPORTED |
| `:window-functions/offset` | LAG, LEAD functions | SUPPORTED |

### 8.5 Metadata Feature Flags

| Feature Flag | Description | ScratchBird Status |
|--------------|-------------|-------------------|
| `:metadata/key-constraints` | FK constraint enforcement | SUPPORTED |
| `:describe-fields` | Custom field metadata | SUPPORTED |
| `:describe-indexes` | Index information | SUPPORTED |
| `:table-privileges` | Privilege sync | SUPPORTED |
| `:nested-field-columns` | JSON column unfolding | TBD |

### 8.6 Upload Feature Flags

| Feature Flag | Description | ScratchBird Status |
|--------------|-------------|-------------------|
| `:uploads` | CSV upload to tables | TBD |
| `:upload-with-auto-pk` | Auto-increment PK on upload | TBD |

### 8.7 Connection Feature Flags

| Feature Flag | Description | ScratchBird Status |
|--------------|-------------|-------------------|
| `:connection/multiple-databases` | Single connection = multiple DBs | NO (standard RDBMS) |
| `:uuid-type` | Native UUID support | SUPPORTED |
| `:identifiers-with-spaces` | Spaces in identifiers | SUPPORTED |

---

## 9. Semantic Types

### 9.1 Overview

Semantic types add meaning to fields for Metabase's UI and functionality:

```
Database Type → Metabase Base Type → Semantic Type
VARCHAR(255) → :type/Text         → :type/Email
INTEGER      → :type/Integer      → :type/FK
```

### 9.2 Semantic Type Categories

#### 9.2.1 Key Types

| Semantic Type | Description | Auto-Detection |
|---------------|-------------|----------------|
| `:type/PK` | Primary key | Column in PK constraint |
| `:type/FK` | Foreign key | Column in FK constraint |

#### 9.2.2 Numeric Semantic Types

| Semantic Type | Description | Auto-Detection |
|---------------|-------------|----------------|
| `:type/Quantity` | Counts/amounts | Column name contains "qty", "quantity", "count" |
| `:type/Score` | Ratings/scores | Column name contains "score", "rating" |
| `:type/Percentage` | Percentages | Column name contains "percent", "pct" |
| `:type/Currency` | Money values | MONEY type or "price", "cost", "amount" |
| `:type/Discount` | Discount amounts | Column name contains "discount" |
| `:type/Income` | Revenue/income | Column name contains "income", "revenue" |
| `:type/Latitude` | Geographic latitude | Column name contains "lat", "latitude" |
| `:type/Longitude` | Geographic longitude | Column name contains "lon", "lng", "longitude" |

#### 9.2.3 Temporal Semantic Types

| Semantic Type | Description | Auto-Detection |
|---------------|-------------|----------------|
| `:type/CreationDate` | Record creation date | "created_at", "creation_date" |
| `:type/CreationTime` | Record creation time | "created_time" |
| `:type/CreationTimestamp` | Creation timestamp | "created_at" on timestamp |
| `:type/JoinedDate` | User join date | "joined_at", "signup_date" |
| `:type/JoinedTime` | User join time | "joined_time" |
| `:type/JoinedTimestamp` | Join timestamp | "joined_at" on timestamp |
| `:type/Birthdate` | Date of birth | "birth_date", "dob", "birthday" |
| `:type/CancelationDate` | Cancelation date | "canceled_at", "cancelled_at" |

#### 9.2.4 Text Semantic Types

| Semantic Type | Description | Auto-Detection |
|---------------|-------------|----------------|
| `:type/Name` | Person/entity name | "name", "full_name" |
| `:type/Title` | Title/heading | "title" |
| `:type/Description` | Long description | "description", "desc" |
| `:type/Email` | Email address | "email", validated pattern |
| `:type/URL` | Web URL | "url", "link", validated pattern |
| `:type/ImageURL` | Image URL | "image_url", "photo_url" |
| `:type/AvatarURL` | Avatar image | "avatar_url", "avatar" |
| `:type/Category` | Categorical data | Low distinct count, repeated values |
| `:type/Source` | Data source | "source", "origin" |
| `:type/Product` | Product name | "product", "product_name" |
| `:type/Company` | Company name | "company", "organization" |
| `:type/City` | City name | "city" |
| `:type/State` | State/province | "state", "province" |
| `:type/Country` | Country | "country" |
| `:type/ZipCode` | Postal code | "zip", "zip_code", "postal_code" |

#### 9.2.5 Other Semantic Types

| Semantic Type | Description | Auto-Detection |
|---------------|-------------|----------------|
| `:type/SerializedJSON` | JSON data | JSON/JSONB type |
| `:type/Enum` | Enumerated values | ENUM type |
| `:type/Comment` | Comments/notes | "comment", "note" |
| `:type/UNIXTimestamp` | Unix epoch timestamp | Integer with timestamp-like values |

### 9.3 Fingerprinting

Metabase analyzes sample data to determine semantic types:

```sql
-- Sample 10,000 rows for fingerprinting
SELECT * FROM "schema"."table" LIMIT 10000;
```

**Fingerprint Metrics:**

| Metric | Purpose |
|--------|---------|
| Distinct count | Category detection |
| NULL percentage | Data quality |
| Min/Max values | Numeric range |
| Average/Median | Distribution |
| Sample values | Pattern detection |

---

## 10. Implementation Strategies

### 10.1 Strategy Comparison

| Strategy | Complexity | Maintenance | Features | Branding |
|----------|------------|-------------|----------|----------|
| PostgreSQL Compatibility | Low | Low | Full PG features | "PostgreSQL" |
| JDBC Driver + Plugin | Medium | Medium | Full control | "ScratchBird" |
| Native Clojure Driver | High | High | Maximum control | "ScratchBird" |

### 10.2 Recommended Strategy: ScratchBird JDBC + Metabase Plugin

**Rationale:**
- Uses native ScratchBird protocol (SBWP v1.1) on port 3092
- Full control of branding and driver behavior
- Leverages `sql-jdbc` parent for MBQL translation and query execution
- No reliance on PostgreSQL catalog emulation

**Requirements:**
1. ScratchBird JDBC driver is available on Metabase classpath
2. Driver plugin implements connection schema and feature flags
3. Catalog metadata is available via JDBC metadata or SQL queries
4. Query execution honors prepared statements and binary-only params

### 10.3 Alternative Strategy: PostgreSQL Compatibility

**When to use:**
- Need zero Metabase plugin deployment
- Already running a PostgreSQL listener for ScratchBird

**Components:**
1. ScratchBird PostgreSQL compatibility listener
2. PostgreSQL catalog and information_schema views
3. PostgreSQL type OIDs and SQL syntax parity

---

## 11. PostgreSQL Compatibility Path

**Optional fallback:** Only required if you want to use Metabase's built-in
PostgreSQL driver instead of the ScratchBird plugin.

### 11.1 Required Catalog Views

#### 11.1.1 pg_namespace (Schemas)

```sql
CREATE VIEW pg_catalog.pg_namespace AS
SELECT
    schema_id AS oid,
    schema_name AS nspname,
    owner_id AS nspowner,
    NULL::text[] AS nspacl
FROM sb_schemas;
```

**Required Columns:**

| Column | Type | Description |
|--------|------|-------------|
| oid | oid | Schema OID |
| nspname | name | Schema name |
| nspowner | oid | Owner role OID |
| nspacl | aclitem[] | Access privileges |

#### 11.1.2 pg_class (Tables/Views/Indexes)

```sql
CREATE VIEW pg_catalog.pg_class AS
SELECT
    object_id AS oid,
    object_name AS relname,
    schema_id AS relnamespace,
    CASE object_type
        WHEN 'TABLE' THEN 'r'
        WHEN 'VIEW' THEN 'v'
        WHEN 'INDEX' THEN 'i'
        WHEN 'SEQUENCE' THEN 'S'
        WHEN 'MATERIALIZED VIEW' THEN 'm'
    END AS relkind,
    -- ... other columns
FROM sb_objects;
```

**Required Columns:**

| Column | Type | Description |
|--------|------|-------------|
| oid | oid | Object OID |
| relname | name | Object name |
| relnamespace | oid | Schema OID |
| relkind | char | Object type (r/v/i/S/m/f/p) |
| relowner | oid | Owner OID |
| reltuples | float4 | Estimated row count |
| relpages | int4 | Page count |
| relhasindex | bool | Has indexes |
| relispopulated | bool | Populated (for matviews) |

#### 11.1.3 pg_attribute (Columns)

```sql
CREATE VIEW pg_catalog.pg_attribute AS
SELECT
    table_id AS attrelid,
    column_name AS attname,
    type_oid AS atttypid,
    -1 AS attstattarget,
    type_length AS attlen,
    column_position AS attnum,
    type_modifier AS atttypmod,
    NOT is_nullable AS attnotnull,
    has_default AS atthasdef,
    FALSE AS attisdropped,
    -- ... other columns
FROM sb_columns;
```

**Required Columns:**

| Column | Type | Description |
|--------|------|-------------|
| attrelid | oid | Table OID |
| attname | name | Column name |
| atttypid | oid | Type OID |
| attnum | int2 | Column position (1-based) |
| atttypmod | int4 | Type modifier |
| attnotnull | bool | NOT NULL constraint |
| atthasdef | bool | Has default value |
| attisdropped | bool | Column dropped |

#### 11.1.4 pg_type (Data Types)

```sql
CREATE VIEW pg_catalog.pg_type AS
SELECT
    type_oid AS oid,
    type_name AS typname,
    schema_oid AS typnamespace,
    type_length AS typlen,
    TRUE AS typbyval,
    type_category AS typcategory,
    -- ... other columns
FROM sb_types;
```

**Required Columns:**

| Column | Type | Description |
|--------|------|-------------|
| oid | oid | Type OID |
| typname | name | Type name |
| typnamespace | oid | Schema OID |
| typlen | int2 | Fixed size (-1 for variable) |
| typtype | char | Type kind (b/c/d/e/p/r) |
| typcategory | char | Category (A/B/D/N/S/T/U/etc.) |
| typelem | oid | Array element type |
| typarray | oid | Array type OID |

#### 11.1.5 pg_constraint (Constraints)

```sql
CREATE VIEW pg_catalog.pg_constraint AS
SELECT
    constraint_id AS oid,
    constraint_name AS conname,
    schema_oid AS connamespace,
    CASE constraint_type
        WHEN 'PRIMARY KEY' THEN 'p'
        WHEN 'FOREIGN KEY' THEN 'f'
        WHEN 'UNIQUE' THEN 'u'
        WHEN 'CHECK' THEN 'c'
        WHEN 'EXCLUDE' THEN 'x'
    END AS contype,
    table_oid AS conrelid,
    referenced_table_oid AS confrelid,
    key_columns AS conkey,
    referenced_columns AS confkey,
    -- ... other columns
FROM sb_constraints;
```

**Required Columns:**

| Column | Type | Description |
|--------|------|-------------|
| oid | oid | Constraint OID |
| conname | name | Constraint name |
| connamespace | oid | Schema OID |
| contype | char | Type (p/f/u/c/x) |
| conrelid | oid | Table OID |
| confrelid | oid | Referenced table OID |
| conkey | int2[] | Key column numbers |
| confkey | int2[] | Referenced column numbers |

#### 11.1.6 pg_index (Indexes)

```sql
CREATE VIEW pg_catalog.pg_index AS
SELECT
    index_oid AS indexrelid,
    table_oid AS indrelid,
    key_column_count AS indnatts,
    is_unique AS indisunique,
    is_primary AS indisprimary,
    is_valid AS indisvalid,
    key_columns AS indkey,
    -- ... other columns
FROM sb_indexes;
```

**Required Columns:**

| Column | Type | Description |
|--------|------|-------------|
| indexrelid | oid | Index OID |
| indrelid | oid | Table OID |
| indnatts | int2 | Number of columns |
| indisunique | bool | Is unique |
| indisprimary | bool | Is primary key |
| indisvalid | bool | Is valid/usable |
| indkey | int2vector | Column numbers |

### 11.2 Information Schema Views

Also implement standard `information_schema` views:

| View | Purpose |
|------|---------|
| `information_schema.schemata` | Schema listing |
| `information_schema.tables` | Table listing |
| `information_schema.columns` | Column details |
| `information_schema.table_constraints` | Constraint listing |
| `information_schema.key_column_usage` | Key columns |
| `information_schema.referential_constraints` | FK details |
| `information_schema.constraint_column_usage` | Constraint columns |
| `information_schema.views` | View definitions |
| `information_schema.routines` | Functions/procedures |

### 11.3 PostgreSQL Functions

Implement PostgreSQL-compatible functions:

| Function | Purpose |
|----------|---------|
| `pg_catalog.format_type(oid, int4)` | Format type name |
| `pg_catalog.pg_get_expr(text, oid)` | Get expression text |
| `pg_catalog.current_database()` | Current database name |
| `pg_catalog.current_schema()` | Current schema name |
| `pg_catalog.current_user` | Current user name |
| `pg_catalog.pg_table_size(oid)` | Table size in bytes |
| `pg_catalog.pg_relation_size(oid)` | Relation size |

---

## 12. JDBC Driver Requirements

### 12.1 Required JDBC Interfaces

For a Metabase-compatible JDBC driver:

| Interface | Purpose | Priority |
|-----------|---------|----------|
| `java.sql.Driver` | Driver registration | REQUIRED |
| `java.sql.Connection` | Database connection | REQUIRED |
| `java.sql.Statement` | SQL execution | REQUIRED |
| `java.sql.PreparedStatement` | Parameterized queries | REQUIRED |
| `java.sql.ResultSet` | Query results | REQUIRED |
| `java.sql.ResultSetMetaData` | Result column info | REQUIRED |
| `java.sql.DatabaseMetaData` | Schema introspection | REQUIRED |

**ScratchBird JDBC specifics:**
- Driver class: `com.scratchbird.jdbc.SBDriver`
- Protocol: SBWP v1.1 (binary-only parameter binding)
- TLS required (reject `sslmode=disable`)
- Prepared statements must map to PARSE/BIND/EXECUTE on the wire

### 12.2 DatabaseMetaData Methods

Critical methods for Metabase sync:

| Method | Purpose | Priority |
|--------|---------|----------|
| `getSchemas()` | List schemas | REQUIRED |
| `getTables()` | List tables | REQUIRED |
| `getColumns()` | List columns | REQUIRED |
| `getPrimaryKeys()` | Get PK columns | REQUIRED |
| `getImportedKeys()` | Get FK relationships | REQUIRED |
| `getExportedKeys()` | Get referencing FKs | Recommended |
| `getIndexInfo()` | Get index details | Recommended |
| `getTypeInfo()` | Supported types | Recommended |
| `getCatalogs()` | List catalogs | Required for multi-DB |
| `getDatabaseProductName()` | Database name | REQUIRED |
| `getDatabaseProductVersion()` | Version string | REQUIRED |

### 12.3 Connection URL Format

```
jdbc:scratchbird://host:port/database?param=value

Examples:
jdbc:scratchbird://localhost:3092/mydb
jdbc:scratchbird://localhost:3092/mydb?sslmode=require
jdbc:scratchbird://localhost:3092/mydb?user=admin&password=secret&sslmode=require
```

### 12.4 Type Mapping

```java
// In ScratchBird JDBC driver
public class ScratchBirdResultSetMetaData implements ResultSetMetaData {
    @Override
    public int getColumnType(int column) {
        String sbType = getColumnTypeName(column);
        switch (sbType) {
            case "INTEGER": return Types.INTEGER;
            case "BIGINT": return Types.BIGINT;
            case "TEXT":
            case "VARCHAR": return Types.VARCHAR;
            case "BOOLEAN": return Types.BOOLEAN;
            case "DATE": return Types.DATE;
            case "TIMESTAMP": return Types.TIMESTAMP;
            case "TIMESTAMPTZ": return Types.TIMESTAMP_WITH_TIMEZONE;
            case "NUMERIC":
            case "DECIMAL": return Types.DECIMAL;
            case "FLOAT":
            case "REAL": return Types.REAL;
            case "DOUBLE PRECISION": return Types.DOUBLE;
            case "UUID": return Types.OTHER;  // or Types.CHAR for compatibility
            case "JSON":
            case "JSONB": return Types.OTHER;
            default: return Types.OTHER;
        }
    }
}
```

---

## 13. Minimum Viable Implementation

### 13.1 Phase 1: Plugin + Connectivity

**Goal:** Metabase can connect using the ScratchBird driver plugin.

**Tasks:**

| Task | Priority | Status |
|------|----------|--------|
| Build plugin skeleton (manifest, deps, namespace) | P0 | TODO |
| Implement connection properties schema | P0 | TODO |
| Implement `connection-details->spec` (JDBC URL + props) | P0 | TODO |
| Validate TLS requirement (reject sslmode=disable) | P0 | TODO |
| Basic `can-connect?` + `display-name` | P0 | TODO |
| Basic metadata via JDBC `DatabaseMetaData` | P1 | TODO |

**Acceptance Criteria:**
- [ ] Metabase lists "ScratchBird" as a database option
- [ ] Connection test passes using port 3092
- [ ] Basic sync finds schemas, tables, and columns

### 13.2 Phase 2: Sync/Scan + Type Mapping

**Goal:** Sync and scan complete with accurate type mapping.

**Tasks:**

| Task | Priority | Status |
|------|----------|--------|
| Implement or override `describe-database` and `describe-table` | P0 | TODO |
| Verify `DatabaseMetaData` maps to Metabase base types | P0 | TODO |
| Validate fingerprinting queries (scan) | P1 | TODO |
| Add FK and index metadata if available | P1 | TODO |

**Acceptance Criteria:**
- [ ] Metabase data model shows correct base types
- [ ] FK relationships are detected (or gracefully absent)

### 13.3 Phase 3: Query Compatibility

**Goal:** Full query builder support.

**Tasks:**

| Task | Priority | Status |
|------|----------|--------|
| Verify basic SELECT works | P0 | TODO |
| Verify GROUP BY + aggregations | P0 | TODO |
| Verify JOINs | P0 | TODO |
| Verify date functions | P1 | TODO |
| Verify string functions | P1 | TODO |
| Verify window functions | P2 | TODO |
| Test LIMIT/OFFSET pagination | P0 | TODO |

**Acceptance Criteria:**
- [ ] Query builder can construct all basic queries
- [ ] Custom expressions work
- [ ] Date breakouts work (by day/week/month/year)
- [ ] Filters work for all data types

### 13.4 Phase 4: Advanced Features

**Goal:** Full Metabase feature support

**Tasks:**

| Task | Priority | Status |
|------|----------|--------|
| JSON column unfolding | P2 | TODO |
| Native query support | P0 | TODO |
| Saved questions | P0 | TODO |
| Dashboard creation | P0 | TODO |
| Alert configuration | P2 | TODO |
| User permissions sync | P3 | TODO |

### 13.5 Verification Queries

Run these queries to verify compatibility:

```sql
-- 1. Schema discovery
SELECT nspname FROM pg_namespace
WHERE nspname NOT IN ('pg_catalog', 'information_schema');

-- 2. Table discovery
SELECT c.relname, n.nspname, c.relkind
FROM pg_class c
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE c.relkind IN ('r', 'v')
  AND n.nspname = 'public';

-- 3. Column discovery
SELECT a.attname, pg_catalog.format_type(a.atttypid, a.atttypmod)
FROM pg_attribute a
JOIN pg_class c ON a.attrelid = c.oid
WHERE c.relname = 'your_table'
  AND a.attnum > 0
  AND NOT a.attisdropped;

-- 4. Primary key discovery
SELECT a.attname
FROM pg_index i
JOIN pg_attribute a ON a.attrelid = i.indrelid
  AND a.attnum = ANY(i.indkey)
WHERE i.indrelid = 'public.your_table'::regclass
  AND i.indisprimary;

-- 5. Foreign key discovery
SELECT
    tc.constraint_name,
    kcu.column_name,
    ccu.table_name AS foreign_table,
    ccu.column_name AS foreign_column
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_name = 'your_table';

-- 6. Basic aggregation
SELECT COUNT(*), AVG(numeric_col), MAX(date_col)
FROM your_table
WHERE status = 'active'
GROUP BY category;

-- 7. Date truncation
SELECT DATE_TRUNC('month', created_at) AS month, COUNT(*)
FROM your_table
GROUP BY 1
ORDER BY 1;

-- 8. Window function
SELECT
    id,
    value,
    SUM(value) OVER (ORDER BY created_at) AS running_total
FROM your_table;
```

---

## 14. Testing Requirements

### 14.1 Unit Tests

| Test Category | Description |
|---------------|-------------|
| Catalog view correctness | Verify pg_* views return correct data |
| Type mapping accuracy | Verify OID → base type mapping |
| SQL function output | Verify function return values |

### 14.2 Integration Tests

| Test Category | Description |
|---------------|-------------|
| Metabase sync | Complete sync with test database |
| Query builder | All query types execute correctly |
| Dashboard rendering | Visualizations display properly |
| Error handling | Graceful handling of unsupported features |

### 14.3 Compatibility Test Suite

```bash
# Run Metabase with the ScratchBird driver plugin mounted
docker run -d -p 3000:3000 \
  -e MB_DB_TYPE=postgres \
  -e MB_DB_HOST=host.docker.internal \
  -e MB_DB_PORT=5432 \
  -e MB_DB_DBNAME=metabase_app \
  -e MB_DB_USER=metabase \
  -e MB_DB_PASS=password \
  -e MB_PLUGINS_DIR=/plugins \
  -v /path/to/scratchbird-metabase-driver.jar:/plugins/scratchbird-metabase-driver.jar \
  metabase/metabase

# Run test queries via Metabase API
# Create a ScratchBird database connection (example API payload)
curl -X POST http://localhost:3000/api/database \
  -H "Content-Type: application/json" \
  -H "X-Metabase-Session: <SESSION_TOKEN>" \
  -d '{"engine":"scratchbird","name":"ScratchBird","details":{"host":"host.docker.internal","port":3092,"db":"scratchbird_test","user":"metabase","password":"password","sslmode":"require"}}'

# Run test queries via Metabase API
curl -X POST http://localhost:3000/api/dataset \
  -H "Content-Type: application/json" \
  -H "X-Metabase-Session: <SESSION_TOKEN>" \
  -d '{"database": 1, "native": {"query": "SELECT 1"}}'
```

### 14.4 Test Database Schema

Create a test database with representative data:

```sql
-- Test schema for Metabase compatibility
CREATE SCHEMA metabase_test;

CREATE TABLE metabase_test.users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    name VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'active'
);

CREATE TABLE metabase_test.orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES metabase_test.users(id),
    amount DECIMAL(10,2),
    order_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE metabase_test.products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200),
    category VARCHAR(50),
    price DECIMAL(10,2),
    metadata JSONB
);

CREATE TABLE metabase_test.order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES metabase_test.orders(id),
    product_id INTEGER REFERENCES metabase_test.products(id),
    quantity INTEGER,
    unit_price DECIMAL(10,2)
);

-- Insert test data
INSERT INTO metabase_test.users (email, name, status) VALUES
    ('alice@example.com', 'Alice Smith', 'active'),
    ('bob@example.com', 'Bob Jones', 'active'),
    ('carol@example.com', 'Carol White', 'inactive');

-- ... additional test data
```

---

## 15. References

### 15.1 Official Metabase Documentation

- [Database driver basics](https://www.metabase.com/docs/latest/developers-guide/drivers/basics)
- [Guide to writing a Metabase driver](https://www.metabase.com/docs/latest/developers-guide/drivers/start)
- [Implementing multimethods](https://www.metabase.com/docs/latest/developers-guide/drivers/multimethods)
- [Driver interface changelog](https://www.metabase.com/docs/latest/developers-guide/driver-changelog)
- [Syncing and scanning databases](https://www.metabase.com/docs/latest/databases/sync-scan)
- [Data types and semantic types](https://www.metabase.com/docs/latest/data-modeling/semantic-types)

### 15.2 Metabase GitHub Resources

- [Writing A Driver Wiki](https://github.com/metabase/metabase/wiki/Writing-A-Driver)
- [PostgreSQL driver source](https://github.com/metabase/metabase/blob/master/src/metabase/driver/postgres.clj)
- [Sample driver repository](https://github.com/metabase/sample-driver)
- [Community drivers list](https://www.metabase.com/docs/latest/developers-guide/community-drivers)

### 15.3 PostgreSQL Documentation

- [System Catalogs](https://www.postgresql.org/docs/current/catalogs.html)
- [Information Schema](https://www.postgresql.org/docs/current/information-schema.html)
- [Type OIDs](https://www.postgresql.org/docs/current/datatype-oid.html)

### 15.4 ScratchBird Internal References

- PostgreSQL Parser: `src/parser/postgresql/pg_parser.cpp`
- PostgreSQL Adapter: `src/protocol/adapters/postgresql_adapter.cpp`
- Catalog Manager: `src/core/catalog_manager.cpp`
- Type System: `include/scratchbird/core/types.h`

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-22 | Research | Initial specification |

---

**Next Steps:**

1. Review this specification with development team
2. Prioritize Phase 1 tasks for PostgreSQL catalog compatibility
3. Create tracking tickets for each implementation task
4. Set up Metabase test environment for validation
5. Update ScratchBird PostgreSQL adapter as needed
