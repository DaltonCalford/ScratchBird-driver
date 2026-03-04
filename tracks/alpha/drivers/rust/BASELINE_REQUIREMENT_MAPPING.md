# Baseline Requirement Mapping (RUSTBL -> JDBC Baseline)

Last updated: 2026-03-04

| RUSTBL group | JDBC baseline group | Current status | Evidence anchors (lane source/tests) |
| --- | --- | --- | --- |
| CONN | JDBCBL-CONN | Partial | `src/config.rs:81`, `src/config.rs:95`, `src/config.rs:122`, `src/client.rs:236`, `src/client.rs:250`, `src/client.rs:352`, `src/client.rs:1708`, `src/client.rs:1725`, `src/client.rs:1977`, `src/client.rs:1988`, `tests/config_test.rs:52`, `tests/config_test.rs:63`, `tests/config_test.rs:71`, `tests/integration_test.rs:21` |
| TXN | JDBCBL-TXN | Partial | `src/client.rs:596`, `src/client.rs:641`, `src/client.rs:651`, `src/client.rs:661`, `src/client.rs:671`, `src/client.rs:681`, `src/client.rs:1917`, `src/client.rs:1924`, `src/client.rs:1944`, `src/protocol.rs:547`, `src/protocol.rs:569`, `src/protocol.rs:573`, `src/protocol.rs:577`, `src/client.rs:2275`, `src/client.rs:2291` |
| EXEC | JDBCBL-EXEC | Implemented | `src/client.rs:366`, `src/client.rs:371`, `src/client.rs:391`, `src/client.rs:406`, `src/client.rs:425`, `src/client.rs:433`, `src/client.rs:483`, `src/client.rs:491`, `src/client.rs:1493`, `src/sql.rs:43`, `src/sql.rs:63`, `src/sql.rs:68`, `tests/sql_test.rs:70`, `tests/sql_test.rs:81`, `tests/sql_test.rs:92`, `src/client.rs:2251`, `src/client.rs:2263`, `tests/integration_test.rs:77`, `tests/integration_test.rs:111`, `tests/integration_test.rs:140`, `tests/integration_test.rs:169` |
| META | JDBCBL-META | Partial | `src/metadata.rs:12`, `src/metadata.rs:51`, `src/metadata.rs:85`, `src/metadata.rs:111`, `src/metadata.rs:161`, `src/metadata.rs:180`, `src/metadata.rs:237`, `src/client.rs:559`, `src/client.rs:572`, `src/client.rs:579`, `src/client.rs:2148`, `src/client.rs:2282`, `tests/metadata_test.rs:17`, `tests/metadata_test.rs:51`, `tests/metadata_test.rs:76`, `tests/metadata_test.rs:103`, `tests/metadata_test.rs:158`, `tests/integration_test.rs:188` (metadata helpers cover recursive schema shaping plus extended collection alias/query resolution, including unified `routines`; `Client` exposes collection-routed execution and restriction-aware filtering via `query_metadata_with_restrictions(...)` with collection-scoped allowed restriction families, alias-column matching, null matching, and unknown-key ignore behavior covered by unit and integration tests. Status remains partial pending deeper live metadata coverage and broader DDL-editor payload parity checks.) |
| TYPE | JDBCBL-TYPE | Implemented | `src/types.rs:194`, `src/types.rs:226`, `src/types.rs:417`, `src/types.rs:478`, `src/types.rs:1083`, `tests/types_test.rs:11`, `tests/types_test.rs:21`, `tests/types_test.rs:34`, `tests/integration_test.rs:53` |
| ERR | JDBCBL-ERR | Implemented | `src/errors.rs:11`, `src/errors.rs:86`, `src/protocol.rs:1007`, `src/client.rs:1364`, `src/client.rs:1377` |
| RES | JDBCBL-RES | Implemented | `src/client.rs:93`, `src/client.rs:1051`, `src/client.rs:1426`, `src/client.rs:1489`, `src/protocol.rs:794`, `src/protocol.rs:864`, `src/protocol.rs:914`, `tests/integration_test.rs:25`, `tests/integration_test.rs:44` |

## Notes on status

- `Implemented`: lane code has working path(s) plus direct source/test evidence.
- `Partial`: lane code has baseline path(s), but coverage depth or validation breadth is limited.
- `Gap`: baseline surface is not yet exposed as callable driver behavior in this lane.
