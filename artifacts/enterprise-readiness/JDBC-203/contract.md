# JDBC-203 Cross-Runtime Pooling and Error-Recovery Contract

## Purpose
Define a deterministic contract for .NET and JDBC behavior on pooling, cancellation, timeout, and error-recovery paths. This gate blocks .NET/JDBC P0 release until both runtimes match expected behavior.

## Scope
- Drivers: `tracks/alpha/drivers/dotnet`, `tracks/alpha/drivers/jdbc`
- Runtime APIs: connection lifecycle, command execution reuse, transaction recovery, pool saturation, and cancellation
- Required environments:
- ScratchBird server (managed/listener)
- .NET test runner with:
  - `SCRATCHBIRD_DOTNET_URL` in `scratchbird://host:port/database?...` or key/value form (`host=...;port=...;database=...`)
  - `SCRATCHBIRD_DOTNET_CANCEL_SQL`
- JDBC test runner with:
  - `SCRATCHBIRD_JDBC_URL` in `jdbc:scratchbird://host:port/database?...` format
  - `SCRATCHBIRD_JDBC_CANCEL_SQL`

## Gate Script
- `run_cross_runtime_pool_contract.sh` enforces optional strict mode:
  - Set `JDBC203_STRICT_GATE=true` to block when any required endpoint/cancel environment is missing.
  - The default CI path in `ci.yml` sets `JDBC203_STRICT_GATE` explicitly from repository variable (fallback `false`) to avoid mandatory blocking in environments without both runtimes.
  - Non-strict mode records partial results when only one runtime is reachable.
  - `.NET` contract scenarios run in isolated per-case invocations with a runtime-stack refresh boundary between cases to avoid cross-test listener state carryover.
- Summary file: `contract_gate_summary_<timestamp>.json`.

## Mandatory Rules
1. Borrow and return behavior
   - A borrowed connection must be usable and healthy immediately after open.
   - Releasing a connection after execute/cancel/failure must keep pool in consistent state.
2. Saturation and bounded fallback
   - Under sustained saturation, runtime must either block within bounded time or fail deterministically with actionable error.
3. Failure recovery
   - Cancel and timeout errors must release server resources and pool handles before borrow/next operation.
4. Reconnect correctness
   - After transient connection failure and recovery, both runtimes must continue to borrow and execute statements correctly.
5. Metadata/lob parity after recovery
   - Recovered connections must support metadata and LOB paths without stale-handle errors.

## Evidence requirements
- Command output for each scenario with timestamps.
- Pool counters/health before-and-after each scenario.
- Pass/fail matrix per rule by runtime and scenario.

## Mandatory scenarios
- Scenario A: baseline borrow/reuse after cancel
- Scenario B: timeout-driven cancellation reuse
- Scenario C: concurrent pool stress (at least 10 workers)
- Scenario D: transient network/connection interruption recovery
- Scenario E: metadata and stream reuse after cancellation/reconnect
