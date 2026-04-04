# Driver Specification Index

**[← Back to Specifications Index](../README.md)**

This directory holds driver and metadata specifications that were migrated into
the ScratchBird-driver repository. These specs focus on native SBWP drivers,
ODBC/JDBC, and shared metadata/query contracts.

## Scope Notes

- This repository ships **native SBWP v1.1 drivers** plus CLI tools.
- **Emulated protocol clients (PostgreSQL/MySQL/Firebird)** are not implemented
  here. Use the standard drivers for those engines against ScratchBird's
  emulation listeners in the main engine repo.

## Core Driver Specifications

- **[JDBC_DRIVER_SPECIFICATION.md](JDBC_DRIVER_SPECIFICATION.md)** - JDBC driver requirements
- **[ODBC_DRIVER_SPECIFICATION.md](ODBC_DRIVER_SPECIFICATION.md)** - ODBC 3.8 driver requirements
- **[R2DBC_DRIVER_SPECIFICATION.md](R2DBC_DRIVER_SPECIFICATION.md)** - Reactive Java driver requirements
- **[ADBC_DRIVER_SPECIFICATION.md](ADBC_DRIVER_SPECIFICATION.md)** - Arrow-native database driver requirements
- **[FLIGHT_SQL_DRIVER_SPECIFICATION.md](FLIGHT_SQL_DRIVER_SPECIFICATION.md)** - Flight SQL driver requirements
- **[JULIA_DRIVER_SPECIFICATION.md](JULIA_DRIVER_SPECIFICATION.md)** - Julia database driver requirements
- **[PERL_DBI_DRIVER_SPECIFICATION.md](PERL_DBI_DRIVER_SPECIFICATION.md)** - Perl DBI driver requirements
- **[CLI_TOOLS_SPECIFICATION.md](CLI_TOOLS_SPECIFICATION.md)** - CLI tooling competitive-closure requirements
- **[ALPHA_DRIVER_BOOTSTRAP.md](ALPHA_DRIVER_BOOTSTRAP.md)** - SBWP v1.1 bootstrap rules
- **[NATIVE_DRIVER_CONFORMANCE.md](NATIVE_DRIVER_CONFORMANCE.md)** - SBWP v1.1 conformance checklist
- **[DRIVER_METADATA_QUERY_CONTRACT.md](DRIVER_METADATA_QUERY_CONTRACT.md)** - Metadata query contract
- **[unified_interface_spec.md](unified_interface_spec.md)** - Unified driver interface (reference)

## Language Driver Templates

These templates mirror the Alpha/Beta target driver list in the ScratchBird
specifications and provide per-language spec scaffolding:

- **[language/README.md](language/README.md)** - Language driver templates index

## Current Driver Parity Status

For the current lane-by-lane verdicts, use:
- [../audit/DRIVER_IMPLEMENTATION_AUDIT.md](../audit/DRIVER_IMPLEMENTATION_AUDIT.md)
- [../audit/DRIVER_IMPLEMENTATION_AUDIT_MATRIX.csv](../audit/DRIVER_IMPLEMENTATION_AUDIT_MATRIX.csv)

Current headline state:
- full-parity application-driver lanes: `cpp`, `dotnet`, `go`, `jdbc`, `node`, `pascal`, `php`, `python`, `ruby`, `rust`
- partial application-driver lanes: `dart`, `elixir`, `odbc`, `r`, `swift`
- hybrid lane with remaining native-transport closure gap: `mojo`
- tooling lane outside the JDBC/.NET parity baseline but now in the Beta 1 competitive-closure program: `cli`
- research-backed planned Beta 1 expansion lanes with implementation-ready specs: `r2dbc`, `adbc`, `flightsql`, `julia`, `perl`

Expansion companion material:

- [../reference/beta1_expansion_server_independent_2026-04-03/README.md](../reference/beta1_expansion_server_independent_2026-04-03/README.md)
- [../audit/DRIVER_BETA1_EXPANSION_SERVER_INDEPENDENT_REMAINING_WORK.md](../audit/DRIVER_BETA1_EXPANSION_SERVER_INDEPENDENT_REMAINING_WORK.md)

## Protocol Reference (External)

These docs were migrated for reference and are **not** implemented as client
libraries in this repository:

- **[postgresql_spec.md](postgresql_spec.md)** - PostgreSQL protocol reference
- **[postgresql_technical.md](postgresql_technical.md)** - PostgreSQL technical notes
- **[mysql_mariadb_spec.md](mysql_mariadb_spec.md)** - MySQL/MariaDB protocol reference
- **[firebird_spec.md](firebird_spec.md)** - Firebird protocol reference
- **[mssql_spec.md](mssql_spec.md)** - MSSQL/TDS reference (post-gold)
- **[odbc_generic_spec.md](odbc_generic_spec.md)** - Generic ODBC reference
- **[jdbc_jni_spec.md](jdbc_jni_spec.md)** - JNI integration reference

## Related Specs

- [Client library API](../api/CLIENT_LIBRARY_API_SPECIFICATION.md)
- [Driver metadata contract](DRIVER_METADATA_QUERY_CONTRACT.md)
- [Shared release evidence contract](../DRIVER_RELEASE_READINESS_EVIDENCE_CONTRACT.md)
- [Best-in-class competitive closure model](../DRIVER_BEST_IN_CLASS_COMPETITIVE_CLOSURE_MODEL.md)
- [Main specs index](../README.md)

---

**Last Updated:** 2026-04-03
