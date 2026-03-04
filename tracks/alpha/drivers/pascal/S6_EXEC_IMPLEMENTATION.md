# DLB-PASCAL-007 S6 EXEC Implementation

Date: 2026-03-04  
Lane: `tracks/alpha/drivers/pascal`  
Scope: close `EXEC` evidence gaps with deterministic lane-local tests (adapter `Prepare` lifecycle and stream-control/backpressure behavior).

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

3. Deterministic stream-control/backpressure suite
   - File: `tests/StreamControlBackpressureTests.pas`
   - Added constructor-based transport injection support to client for deterministic wire-flow assertions:
     - `src/ScratchBird.Client.pas`:
       - `constructor CreateWithTransport(const Transport: IScratchBirdTransport)`
       - `procedure InitializeClient(const Transport: IScratchBirdTransport)`
   - Covers:
     - `StreamControl` message emission and payload encoding (`MSG_STREAM_CONTROL`, control/window/timeout).
     - `TScratchBirdResultStream.ReadRow` portal-suspended path emitting `MSG_EXECUTE` resume (`BuildExecutePayload('', CurrentMaxRows)`).
     - command completion metadata (`CommandTag`, `RowsAffected`) through the resume path.

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

3. Stream-control/backpressure suite
   - `fpc -Mdelphi -Fu./tracks/alpha/drivers/pascal/src -FU/tmp/sb_pascal_exec_stream_build -FE/tmp/sb_pascal_exec_stream_bin ./tracks/alpha/drivers/pascal/tests/StreamControlBackpressureTests.pas`
   - `/tmp/sb_pascal_exec_stream_bin/StreamControlBackpressureTests`
   - Result: PASS (`StreamControlBackpressureTests: OK`)

## EXEC Status Recommendation

- Recommendation: keep `PARTIAL`
- Rationale:
  - adapter prepare lifecycle behavior now has explicit deterministic lane-local assertions.
  - stream-control/backpressure wire behavior now has deterministic lane-local assertions.
  - remaining EXEC gap is first-class batch/multi-result/generated-key API coverage.

## Remaining Gaps

1. Add first-class API coverage for batch execution, multi-result traversal, and generated-key retrieval.
