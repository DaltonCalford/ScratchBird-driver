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
- **[ALPHA_DRIVER_BOOTSTRAP.md](ALPHA_DRIVER_BOOTSTRAP.md)** - SBWP v1.1 bootstrap rules
- **[NATIVE_DRIVER_CONFORMANCE.md](NATIVE_DRIVER_CONFORMANCE.md)** - SBWP v1.1 conformance checklist
- **[DRIVER_METADATA_QUERY_CONTRACT.md](DRIVER_METADATA_QUERY_CONTRACT.md)** - Metadata query contract
- **[unified_interface_spec.md](unified_interface_spec.md)** - Unified driver interface (reference)

## Language Driver Templates

These templates mirror the Alpha/Beta target driver list in the ScratchBird
specifications and provide per-language spec scaffolding:

- **[language/README.md](language/README.md)** - Language driver templates index

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
- [Main specs index](../README.md)

---

**Last Updated:** 2026-02-01
