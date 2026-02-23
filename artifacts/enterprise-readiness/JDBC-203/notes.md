# JDBC-203 Verification Notes (2026-02-23)

## Status
Blocked. `JDBC203PoolingAndRecoveryContractTest` and `JDBC203PoolingAndRecoveryContractTests` are committed and in-tree verification is passing; cross-runtime execution remains blocked by missing runtime endpoints and required cancellation SQL envs.

## Evidence
- `artifacts/enterprise-readiness/JDBC-203/contract.md`
- `artifacts/enterprise-readiness/JDBC-203/run_cross_runtime_pool_contract.sh`
- `artifacts/enterprise-readiness/JDBC-203/latest_verification.log`
- `artifacts/enterprise-readiness/JDBC-203/latest_contract_summary.json`
- `artifacts/enterprise-readiness/JDBC-203/contract_run_20260223T043302Z.log`
- `artifacts/enterprise-readiness/JDBC-203/contract_run_20260223T050052Z.log`
- `tracks/alpha/drivers/jdbc/src/main/java/com/scratchbird/jdbc/SBConnectionProperties.java`
- `tracks/alpha/drivers/jdbc/src/main/java/com/scratchbird/jdbc/SBDriver.java`
- `tracks/alpha/drivers/jdbc/src/main/java/com/scratchbird/jdbc/SBConnectionPool.java`
- `tracks/alpha/drivers/jdbc/src/test/java/com/scratchbird/jdbc/JDBC203PoolingAndRecoveryContractTest.java`
- `tracks/alpha/drivers/jdbc && ./gradlew test`
- `tracks/alpha/drivers/jdbc && ./gradlew test --tests com.scratchbird.jdbc.JDBC203PoolingAndRecoveryContractTest`
- `dotnet test tracks/alpha/drivers/dotnet/tests/ScratchBird.Data.Tests/ScratchBird.Data.Tests.csproj`
- `artifacts/enterprise-readiness/JDBC-203/contract_run_20260223T050310Z.log`

## Blocking
- Runtime-wide execution blocked until both `.NET` and `JDBC` CI environments provide valid ScratchBird endpoints with managed/listener toggles.
- The contract run must capture scenario A-E matrix evidence for both runtime clients before gate closure.
- JDBC run additionally requires `SCRATCHBIRD_JDBC_CANCEL_SQL` for scenarios A/B/D/E.
- `SCRATCHBIRD_JDBC_URL` and `SCRATCHBIRD_DOTNET_URL` are required for cross-runtime execution.
- `SCRATCHBIRD_DOTNET_CANCEL_SQL` is required for scenarios A/B/D/E.

## Gate Control
- `JDBC203_STRICT_GATE=true` (default on CI when `GITHUB_ACTIONS=true`) blocks execution if any required endpoint/cancel variable is missing.
- Local runs are partial only when strict gate is disabled and will emit `contract_gate_summary_<timestamp>.json` with status and missing env list.
- `run_cross_runtime_pool_contract.sh` now writes a structured `overallStatus`/`reason` artifact in
  `contract_gate_summary_<timestamp>.json`.
- Each run also writes replay-ready `latest_verification.log` and `latest_contract_summary.json` artifacts.

## Latest Run
- Latest timestamp: from the most recent local run
- Command: `bash artifacts/enterprise-readiness/JDBC-203/run_cross_runtime_pool_contract.sh`
- Result: blocked in non-strict mode due missing runtime/cancel vars; summary file
  `latest_contract_summary.json` and `latest_verification.log` capture the active blocker state and reproduce the run conditions.

## Local Verification (in-tree only)
- `cd tracks/alpha/drivers/jdbc && ./gradlew test --tests com.scratchbird.jdbc.JDBC203PoolingAndRecoveryContractTest`
  - Result: pass (tests skipped when env vars are missing)
- `cd tracks/alpha/drivers/jdbc && ./gradlew test`
  - Result: pass
- `dotnet test tracks/alpha/drivers/dotnet/tests/ScratchBird.Data.Tests/ScratchBird.Data.Tests.csproj --filter "FullyQualifiedName~JDBC203PoolingAndRecoveryContractTests"`
  - Result: pass (5 scenarios, environment-gated by `SCRATCHBIRD_DOTNET_URL` and `SCRATCHBIRD_DOTNET_CANCEL_SQL`; currently skipped locally when envs missing)
