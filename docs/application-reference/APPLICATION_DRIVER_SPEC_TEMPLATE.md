# <Application> Compatibility Specification

**Document Version:** 0.1
**Created:** <YYYY-MM-DD>
**Status:** Draft
**Scope:** Requirements to support <Application> connectivity with ScratchBird

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Application Overview](#2-application-overview)
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

- **Recommended Approach:** <e.g., JDBC plugin, protocol compatibility>
- **Alternative Approach:** <e.g., proxy, existing driver>
- **Critical Dependencies:** <catalog views, metadata APIs, auth>
- **Estimated Complexity:** <Low/Medium/High>

## 2. Application Overview

Describe how the application connects to databases, what driver/plugin system it
uses, and any known constraints (SDK version, runtime, packaging).

## 3. Driver Architecture

- **Driver type:** <JDBC/ODBC/native/protocol compatibility>
- **Driver parent/inheritance:** <if applicable>
- **Packaging format:** <JAR, plugin ZIP, shared library>
- **Runtime requirements:** <Java version, Node version, etc>

## 4. Core Driver Capabilities

List required capabilities for a minimum viable driver:

- Connection test / ping
- Query execution
- Prepared statements / bind support
- Result set metadata
- Schema discovery

## 5. Connection Details Schema

Define the connection properties exposed in the UI and how they map to JDBC/DSN.

**Fields:**
- host (string)
- port (integer)
- db (string)
- user (string)
- password (password)
- sslmode (enum)
- sslrootcert (string)
- sslcert (string)
- sslkey (string)
- application_name (string)
- connectTimeout (integer seconds)
- socketTimeout (integer seconds)

**JDBC URL template:**
```
<driver>://{host}:{port}/{db}?sslmode={sslmode}
```

## 6. Schema Introspection Requirements

List the metadata calls or SQL queries the application uses:

- schema discovery
- table discovery
- column discovery
- primary/foreign keys
- indexes

Include example SQL if the app issues queries directly.

## 7. Data Type Mapping

Map ScratchBird types or OIDs to the application’s base type system.

| ScratchBird Type | Application Base Type | Notes |
|------------------|-----------------------|-------|
| INTEGER | <type> | |
| TEXT | <type> | |

## 8. SQL Query Requirements

Document required SQL features for the app’s query builder:

- SELECT/WHERE/GROUP BY/ORDER BY
- JOINs
- Aggregations
- Date functions
- String functions
- Window functions (if used)

## 9. Feature Flags / Capabilities

Declare which features are advertised as supported and any conditional flags.

## 10. Authentication & Security

- TLS requirements
- Auth methods supported
- Credential storage / rotation

## 11. Error Handling

- Required SQLSTATE mappings
- User-facing error messages
- Retry / backoff behavior

## 12. Implementation Plan

Define phases with acceptance criteria.

## 13. Testing Requirements

- Unit tests
- Integration tests
- Application-specific end-to-end tests

## 14. References

List official docs, SDK references, and sample drivers.
