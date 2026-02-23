# JDBC-203 Verification Notes (2026-02-23)

## Status
In progress. JDBC-side pooling implementation and `JDBC203PoolingAndRecoveryContractTest` are committed and in-tree verification is passing; cross-runtime execution remains blocked by missing runtime endpoints.

## Evidence
- `artifacts/enterprise-readiness/JDBC-203/contract.md`
- `artifacts/enterprise-readiness/JDBC-203/run_cross_runtime_pool_contract.sh`
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
- The contract run must capture pool counters and failure-recovery traces for scenarios A-E before gate closure.
- JDBC run additionally requires `SCRATCHBIRD_JDBC_CANCEL_SQL` for scenarios A/B/D/E.
- `SCRATCHBIRD_JDBC_URL` and `SCRATCHBIRD_DOTNET_URL` are required for cross-runtime execution.
- `SCRATCHBIRD_JDBC_CANCEL_SQL` is required for scenarios A/B/D/E.

## Latest Run
- Timestamp: 2026-02-23T05:03Z
- Command: `bash artifacts/enterprise-readiness/JDBC-203/run_cross_runtime_pool_contract.sh`
- Result: blocked by missing `SCRATCHBIRD_DOTNET_URL` and `SCRATCHBIRD_JDBC_URL`; no cross-runtime scenarios executed.

## Local Verification (in-tree only)
- `cd tracks/alpha/drivers/jdbc && ./gradlew test --tests com.scratchbird.jdbc.JDBC203PoolingAndRecoveryContractTest`
  - Result: pass (tests skipped when env vars are missing)
- `cd tracks/alpha/drivers/jdbc && ./gradlew test`
  - Result: pass
- `dotnet test tracks/alpha/drivers/dotnet/tests/ScratchBird.Data.Tests/ScratchBird.Data.Tests.csproj`
  - Result: pass (36 tests, 0 skipped)
