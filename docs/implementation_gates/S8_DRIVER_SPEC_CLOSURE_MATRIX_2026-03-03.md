# S8 Driver Spec Closure Matrix (2026-03-03)

## Objective
Close all non-JDBC driver lanes from `PARTIAL` to baseline-complete (`MET`) against JDBC baseline groups:
`CONN`, `TXN`, `EXEC`, `META`, `TYPE`, `ERR`, `RES`.

## Source of truth
- `tracks/*/drivers/*/BASELINE_REQUIREMENT_MAPPING.md`
- `docs/implementation_gates/S6_DRIVER_GATE_RESULTS_2026-03-03.md`
- `docs/implementation_gates/S7_PROMOTION_DECISIONS_2026-03-03.md`

## Audit conclusion
- JDBC is the baseline-complete reference lane.
- ODBC is near-complete but still `Partial` for `META` breadth.
- All other lanes retain multi-group `Partial` status and cannot be treated as spec-complete.

## Priority model
- `P0`: missing core transactional/execution/metadata parity used by most applications.
- `P1`: missing type/error/resource hardening and integration depth.
- `P2`: lane-specific transport/runtime maturity gaps.

## Driver matrix
| Driver | Lane | Partial groups | Primary closure blockers | Priority | Wave |
|---|---|---|---|---|---|
| ODBC | `tracks/alpha/drivers/odbc` | `META` | Expand metadata beyond recursive schema shaping to full catalog/key/privilege/type metadata families and richer DDL-editor payload coverage. | P0 | W4 |
| CPP | `tracks/beta/drivers/cpp` | `CONN,TXN,EXEC,META,TYPE,ERR,RES` | Add true named-pipe/embedded transport, savepoint and advanced exec coverage, executable metadata APIs, full value encode/decode tests, SQLSTATE mapping tests, and resource/pool lifecycle tests. | P0 | W4 |
| DOTNET | `tracks/alpha/drivers/dotnet` | `TXN,EXEC,META,TYPE` | Isolation parity expansion, broader command surface parity, fuller `GetSchema` family/restriction support, and deeper type fidelity test matrix. | P0 | W2 |
| GO | `tracks/alpha/drivers/go` | `CONN,TXN,EXEC,META,TYPE,ERR,RES` | Expose savepoint API, add multi-result traversal parity, add executable metadata API, strengthen SQLSTATE mapping tests, and harden resilience/pool lifecycle integration tests. | P0 | W1 |
| RUST | `tracks/alpha/drivers/rust` | `CONN,TXN,EXEC,META` | Increase live connection/auth/proxy parity coverage, broaden transaction lifecycle integration, close advanced execution parity, and add first-class metadata execution surfaces. | P0 | W2 |
| NODE | `tracks/alpha/drivers/node` | `TXN,EXEC,META,TYPE,ERR,RES` | Close autocommit/session-schema parity, add batch/multi-result/generated-key/callable parity, complete metadata family coverage, and strengthen type/error/resource conformance tests. | P0 | W1 |
| PYTHON | `tracks/alpha/drivers/python` | `CONN,TXN,EXEC,META,TYPE,ERR,RES` | Add missing advanced execution surface (multi-result/generated keys/callable), executable metadata API families, SQLSTATE mapping tests, and stronger pool/resilience verification. | P0 | W1 |
| PHP | `tracks/alpha/drivers/php` | `CONN,TXN,EXEC,META,TYPE,ERR` | Increase live auth/txn coverage, close advanced execution parity, add first-class executable metadata APIs, and expand type/error fidelity tests. | P0 | W1 |
| RUBY | `tracks/alpha/drivers/ruby` | `CONN,TXN,EXEC,META,TYPE,ERR,RES` | Add live manager/TLS/SCRAM path coverage, savepoint and stream-state parity, metadata execution APIs, broader type/error tests, and explicit resilience lifecycle tests. | P1 | W2 |
| PASCAL | `tracks/alpha/drivers/pascal` | `CONN,TXN,EXEC,META,TYPE,RES` | Implement adapter `Prepare` paths, expand live TXN/EXEC integration, add client-facing metadata APIs, fill codec gaps (`TIMETZ` and broader geometry/type roundtrip), and finish keepalive/leak placeholders. | P1 | W2 |
| MOJO | `tracks/alpha/drivers/mojo` | `TXN,EXEC,META,TYPE,ERR,RES` | Promote from shim-scaffold parity to full conformance: nested/savepoint TXN, non-skipped prepare/cancel conformance defaults, executable metadata APIs, structured error assertions, and resilience lifecycle hardening. | P2 | W4 |
| CLI | `tracks/alpha/drivers/cli` | `TXN,META,TYPE,RES` | Add savepoint-focused `txn_exec` parity coverage, live metadata-family conformance, explicit typed-value manifest assertions, and RAII-based resource safety hardening. | P1 | W3 |
| DART | `tracks/beta/drivers/dart` | `TXN,EXEC,META,TYPE,ERR,RES` | Add live integration for TXN/EXEC/metadata paths, expand scalar+advanced type tests, introduce structured driver error types, and add deterministic resilience tests. | P1 | W3 |
| SWIFT | `tracks/beta/drivers/swift` | `TXN,EXEC,META,TYPE,ERR,RES` | Add live handshake/TXN/EXEC integration, client-facing metadata execution APIs, broader codec tests, typed wire-error handling tests, and resilience lifecycle tests. | P1 | W3 |
| R | `tracks/beta/drivers/r` | `CONN,TXN,META,TYPE,ERR,RES` | Add non-env-gated live auth/proxy coverage, live transaction semantics validation, DBI metadata surfaces, richer type roundtrip tests, structured condition mapping, and resource lifecycle tests. | P1 | W3 |

## 4-driver parallel execution waves
1. **W1 (P0 core):** GO, NODE, PYTHON, PHP
2. **W2 (P0/P1 core):** DOTNET, RUST, RUBY, PASCAL
3. **W3 (P1 platform):** CLI, DART, SWIFT, R
4. **W4 (P0/P2 specialty):** ODBC, CPP, MOJO, cross-lane gate/regression bundle

## Closure definition (per lane)
A lane is only `MET` when all are true:
1. All seven baseline groups are marked `Implemented`/`MET` in lane mapping.
2. S2 (TXN/EXEC) and S3 (META) reports move from `PARTIAL` to `MET`.
3. Conformance evidence includes non-skipped required paths (`prepare_bind`, `cancel`, metadata families).
4. Integration gates pass using runtime stack (`scripts/driver_runtime_stack.sh up/fixtures/env`).
5. Promotion report updates lane decision from `PARTIAL` to `MET`.

## Next actions
1. Execute W1 in parallel with one worker per lane.
2. Require each lane to land conformance-first tests before implementation patches.
3. Regenerate S6/S7 gate reports after each wave; do not advance wave if any lane in the wave regresses.
