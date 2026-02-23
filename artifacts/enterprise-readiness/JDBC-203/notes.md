# JDBC-203 Verification Notes (2026-02-23)

## Status
In progress. JDBC contract implementation is now in code (pooling properties + JDBC-203 scenario test suite); cross-runtime gate remains blocked until managed/listener endpoints are available for both runtimes.

## Evidence
- `artifacts/enterprise-readiness/JDBC-203/contract.md`
- `artifacts/enterprise-readiness/JDBC-203/run_cross_runtime_pool_contract.sh`
- `artifacts/enterprise-readiness/JDBC-203/contract_run_20260223T043302Z.log`
- `artifacts/enterprise-readiness/JDBC-203/contract_run_20260223T050052Z.log`
- `tracks/alpha/drivers/jdbc/src/main/java/com/scratchbird/jdbc/SBConnectionProperties.java`
- `tracks/alpha/drivers/jdbc/src/main/java/com/scratchbird/jdbc/SBDriver.java`
- `tracks/alpha/drivers/jdbc/src/main/java/com/scratchbird/jdbc/SBConnectionPool.java`
- `tracks/alpha/drivers/jdbc/src/test/java/com/scratchbird/jdbc/JDBC203PoolingAndRecoveryContractTest.java`

## Blocking
- Runtime-wide execution blocked until both `.NET` and `JDBC` CI environments provide valid ScratchBird endpoints with managed/listener toggles.
- The contract run must capture pool counters and failure-recovery traces for scenarios A-E before gate closure.
- JDBC run additionally requires `SCRATCHBIRD_JDBC_CANCEL_SQL` for scenarios A/B/D/E.

## Latest Run
- Timestamp: 2026-02-23T05:00Z
- Result: blocked by missing `SCRATCHBIRD_DOTNET_URL` and `SCRATCHBIRD_JDBC_URL` in this environment; no JDBC/.NET scenarios executed.
- Test execution command: `./gradlew test --tests com.scratchbird.jdbc.JDBC203PoolingAndRecoveryContractTest`
- Command result in this environment: success (tests skipped because environment variables not set).
