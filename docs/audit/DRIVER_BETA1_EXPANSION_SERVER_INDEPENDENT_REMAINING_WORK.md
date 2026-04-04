# Driver Beta 1 Expansion Server-Independent Remaining Work

Status: Current
Last Updated: 2026-04-03

This report isolates the remaining work for the ten newly promoted Beta 1 lanes
after the server-independent specification pass.

## Implementation-Pending Work

| Lane | Kind | Primary Implementation-Pending Work | Authority |
| --- | --- | --- | --- |
| `r2dbc` | `driver` | implement the native reactive transport/client, metadata mapping, and Spring/pool integration | `docs/specifications/drivers/R2DBC_DRIVER_SPECIFICATION.md` |
| `adbc` | `driver` | implement the native ADBC driver, Arrow import/export, metadata/info, and packaging | `docs/specifications/drivers/ADBC_DRIVER_SPECIFICATION.md` |
| `flightsql` | `driver` | implement the Flight SQL transport/client, query/prepared lifecycle, and Arrow stream support | `docs/specifications/drivers/FLIGHT_SQL_DRIVER_SPECIFICATION.md` |
| `julia` | `driver` | implement the Julia package, DBInterface surface, type conversion, and DataFrames/Tables shaping | `docs/specifications/drivers/JULIA_DRIVER_SPECIFICATION.md` |
| `perl` | `driver` | implement the DBI/DBD package, diagnostics, metadata, and CPAN-ready packaging | `docs/specifications/drivers/PERL_DBI_DRIVER_SPECIFICATION.md` |
| `dbt` | `adapter` | implement the adapter package, materializations, metadata/introspection, and packaging | `docs/application-reference/DBT_ADAPTER_COMPATIBILITY_SPECIFICATION.md` |
| `airbyte` | `adapter` | implement the source and destination connectors, protocol handling, and deployment assets | `docs/application-reference/AIRBYTE_CONNECTOR_COMPATIBILITY_SPECIFICATION.md` |
| `powerbi` | `adapter` | implement the Power Query/custom connector path, metadata/type behavior, and deployment packaging | `docs/application-reference/POWERBI_COMPATIBILITY_SPECIFICATION.md` |
| `tableau` | `adapter` | implement the Tableau connectivity surface, metadata/capability behavior, and connector packaging | `docs/application-reference/TABLEAU_COMPATIBILITY_SPECIFICATION.md` |
| `looker` | `adapter` | implement the Looker-facing dialect/connection layer, PDT behavior, and deployment assets | `docs/application-reference/LOOKER_COMPATIBILITY_SPECIFICATION.md` |

## Server-Blocked Work

| Lane | Kind | Primary Server-Blocked Item | Verification Packet |
| --- | --- | --- | --- |
| `r2dbc` | `driver` | prove backpressure, cancellation, pool integration, and publish measured release evidence | `docs/development/server-verification/r2dbc.md` |
| `adbc` | `driver` | prove zero-copy Arrow export/import, bulk ingest, and publish measured release evidence | `docs/development/server-verification/adbc.md` |
| `flightsql` | `driver` | prove query/cancel/partition behavior and publish measured release evidence | `docs/development/server-verification/flightsql.md` |
| `julia` | `driver` | prove DBInterface/DataFrames behavior and publish measured release evidence | `docs/development/server-verification/julia.md` |
| `perl` | `driver` | prove DBI semantics and packaging/install behavior and publish measured release evidence | `docs/development/server-verification/perl.md` |
| `dbt` | `adapter` | prove materializations, snapshots, docs, and tests against a live server | `docs/development/server-verification/dbt.md` |
| `airbyte` | `adapter` | prove source/destination connector behavior and runtime registration in Airbyte | `docs/development/server-verification/airbyte.md` |
| `powerbi` | `adapter` | prove Desktop/gateway install, refresh, and folding behavior | `docs/development/server-verification/powerbi.md` |
| `tableau` | `adapter` | prove live/extract behavior and connector install in supported Tableau environments | `docs/development/server-verification/tableau.md` |
| `looker` | `adapter` | prove SQL Runner, explore, and PDT behavior in supported Looker environments | `docs/development/server-verification/looker.md` |

