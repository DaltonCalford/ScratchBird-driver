# DLB-PASCAL-007 S6 EXEC Implementation

Date: 2026-03-04  
Lane: `tracks/alpha/drivers/pascal`  
Scope: close the adapter `Prepare` lifecycle evidence gap in `EXEC` with deterministic lane-local tests.

## Changes Implemented

1. Adapter execution hooks added for deterministic testing and overrideability
   - Files:
     - `src/ScratchBird.FireDAC.pas`
     - `src/ScratchBird.IBX.pas`
     - `src/ScratchBird.Zeos.pas`
     - `src/ScratchBird.SQLdb.pas`
   - Added overridable methods on adapter connection/database classes:
     - `ExecSQLParams(const Sql; const Params)`
     - `ExecuteQueryParams(const Sql; const Params)`
   - Updated adapter query execution paths to route through these hooks instead of calling `Client` directly.
   - Result: adapter query `Prepare` + `ExecSQL` behavior can be asserted without live network dependencies.

2. New deterministic adapter prepare lifecycle suite
   - File: `tests/AdapterPrepareLifecycleTests.pas`
   - Covers:
     - prepare guardrails when connection/database is missing,
     - normalized SQL + parameter ordering reuse after `Prepare`,
     - prepared snapshot behavior (post-prepare SQL/param mutation does not alter prepared execution payload) for:
       - FireDAC adapter
       - IBX adapter
       - Zeos adapter
       - SQLdb adapter

## Targeted Tests Run

1. Adapter lifecycle suite
   - `mkdir -p /tmp/sb_pascal_exec_build /tmp/sb_pascal_exec_bin`
   - `fpc -Mdelphi -Fu./tracks/alpha/drivers/pascal/src -FU/tmp/sb_pascal_exec_build -FE/tmp/sb_pascal_exec_bin ./tracks/alpha/drivers/pascal/tests/AdapterPrepareLifecycleTests.pas`
   - `/tmp/sb_pascal_exec_bin/AdapterPrepareLifecycleTests`
   - Result: PASS (`AdapterPrepareLifecycleTests: OK`)

2. Regression checks (core lane suites)
   - `fpc -Mdelphi -Fu./tracks/alpha/drivers/pascal/src -FU/tmp/sb_pascal_exec_reg_build -FE/tmp/sb_pascal_exec_reg_bin ./tracks/alpha/drivers/pascal/tests/TxnExecParityTests.pas`
   - `/tmp/sb_pascal_exec_reg_bin/TxnExecParityTests`
   - `fpc -Mdelphi -Fu./tracks/alpha/drivers/pascal/src -FU/tmp/sb_pascal_exec_reg_build -FE/tmp/sb_pascal_exec_reg_bin ./tracks/alpha/drivers/pascal/tests/SqlTests.pas`
   - `/tmp/sb_pascal_exec_reg_bin/SqlTests`
   - Result: PASS (`TxnExecParityTests: OK`, `SqlTests: OK`)

## EXEC Status Recommendation

- Recommendation: keep `PARTIAL`
- Rationale:
  - adapter prepare lifecycle behavior now has explicit deterministic lane-local assertions.
  - remaining EXEC gaps are stream-control/backpressure assertions and first-class batch/multi-result/generated-key APIs.

## Remaining Gaps

1. Add stream-control/backpressure tests (`src/ScratchBird.Client.pas:618` path).
2. Add first-class API coverage for batch execution, multi-result traversal, and generated-key retrieval.
