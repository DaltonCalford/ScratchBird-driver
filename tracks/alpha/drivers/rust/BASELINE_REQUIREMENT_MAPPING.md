# Baseline Requirement Mapping (RUSTBL -> JDBC Baseline)

Last updated: 2026-03-03

| RUSTBL group | JDBC baseline group | Current status | Evidence anchors (lane source/tests) |
| --- | --- | --- | --- |
| CONN | JDBCBL-CONN | Partial | `src/config.rs:81`, `src/config.rs:95`, `src/config.rs:122`, `src/client.rs:197`, `src/client.rs:211`, `src/client.rs:255`, `src/client.rs:264`, `src/client.rs:1014`, `src/client.rs:1274`, `tests/config_test.rs:52`, `tests/config_test.rs:63`, `tests/config_test.rs:71`, `src/client.rs:1606`, `src/client.rs:1618`, `src/client.rs:1666`, `tests/integration_test.rs:16` |
| TXN | JDBCBL-TXN | Partial | `src/client.rs:396`, `src/client.rs:434`, `src/client.rs:443`, `src/client.rs:452`, `src/client.rs:461`, `src/client.rs:470`, `src/client.rs:1453`, `src/client.rs:1460`, `src/client.rs:1477`, `src/client.rs:1491`, `src/protocol.rs:547`, `src/protocol.rs:569`, `src/protocol.rs:573`, `src/protocol.rs:577`, `src/client.rs:1758`, `src/client.rs:1774` |
| EXEC | JDBCBL-EXEC | Partial | `src/client.rs:318`, `src/client.rs:323`, `src/client.rs:1229`, `src/client.rs:1239`, `src/client.rs:1254`, `src/sql.rs:43`, `src/sql.rs:63`, `src/sql.rs:86`, `src/sql.rs:126`, `tests/sql_test.rs:11`, `tests/sql_test.rs:23`, `tests/sql_test.rs:34`, `tests/sql_test.rs:42`, `tests/sql_test.rs:52`, `src/client.rs:1744`, `tests/integration_test.rs:31` |
| META | JDBCBL-META | Partial | `src/metadata.rs:12`, `src/metadata.rs:67`, `src/metadata.rs:96`, `src/metadata.rs:115`, `src/metadata.rs:169`, `src/client.rs:385`, `src/client.rs:404`, `tests/metadata_test.rs:16`, `tests/metadata_test.rs:50`, `tests/metadata_test.rs:75`, `tests/metadata_test.rs:93` (metadata helpers now cover recursive schema shaping plus extended collection alias/query resolution, and `Client` now exposes executable metadata collection routing; status remains partial pending richer restriction mapping and live integration coverage.) |
| TYPE | JDBCBL-TYPE | Implemented | `src/types.rs:194`, `src/types.rs:226`, `src/types.rs:417`, `src/types.rs:478`, `src/types.rs:1083`, `tests/types_test.rs:11`, `tests/types_test.rs:21`, `tests/types_test.rs:34`, `tests/integration_test.rs:53` |
| ERR | JDBCBL-ERR | Implemented | `src/errors.rs:11`, `src/errors.rs:86`, `src/protocol.rs:1007`, `src/client.rs:1364`, `src/client.rs:1377` |
| RES | JDBCBL-RES | Implemented | `src/client.rs:93`, `src/client.rs:1051`, `src/client.rs:1426`, `src/client.rs:1489`, `src/protocol.rs:794`, `src/protocol.rs:864`, `src/protocol.rs:914`, `tests/integration_test.rs:25`, `tests/integration_test.rs:44` |

## Notes on status

- `Implemented`: lane code has working path(s) plus direct source/test evidence.
- `Partial`: lane code has baseline path(s), but coverage depth or validation breadth is limited.
- `Gap`: baseline surface is not yet exposed as callable driver behavior in this lane.
