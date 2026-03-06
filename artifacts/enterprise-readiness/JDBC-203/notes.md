# JDBC-203 Verification Notes (2026-03-06)

## Status
Verification complete (gate implementation). Cross-runtime contract enforcement is now strict for both runtimes and supports profile-matrix execution (`direct`, `manager`, `listener`) with per-profile endpoint/cancel requirements.

## What changed
- Reworked `run_cross_runtime_pool_contract.sh` to:
  - require and validate both runtime endpoint + cancel SQL inputs per selected profile
  - enforce JDBC URL scheme (`jdbc:scratchbird:`) and normalize legacy `.NET` `sb://` URLs
  - run all five Scenario A-E contract cases for `.NET` and JDBC per profile
  - emit structured per-profile status in summary JSON
  - preserve strict gate behavior (`JDBC203_STRICT_GATE`) with release-freeze reasons.
- Added profile-matrix controls:
  - `JDBC203_PROFILES=direct[,manager][,listener]`
  - profile-specific URLs:
    - `SCRATCHBIRD_DOTNET_MANAGER_URL`, `SCRATCHBIRD_JDBC_MANAGER_URL`
    - `SCRATCHBIRD_DOTNET_LISTENER_URL`, `SCRATCHBIRD_JDBC_LISTENER_URL`
  - optional profile-specific cancel SQL overrides:
    - `SCRATCHBIRD_DOTNET_MANAGER_CANCEL_SQL`, `SCRATCHBIRD_JDBC_MANAGER_CANCEL_SQL`
    - `SCRATCHBIRD_DOTNET_LISTENER_CANCEL_SQL`, `SCRATCHBIRD_JDBC_LISTENER_CANCEL_SQL`
- Kept static runtime env autoload (`scripts/driver_runtime_stack.sh`) for direct profile bootstrap when available.

## Evidence
- `artifacts/enterprise-readiness/JDBC-203/contract.md`
- `artifacts/enterprise-readiness/JDBC-203/run_cross_runtime_pool_contract.sh`
- `artifacts/enterprise-readiness/JDBC-203/latest_verification.log`
- `artifacts/enterprise-readiness/JDBC-203/latest_contract_summary.json`
- `tracks/alpha/drivers/jdbc/src/test/java/com/scratchbird/jdbc/JDBC203PoolingAndRecoveryContractTest.java`
- `tracks/alpha/drivers/dotnet/tests/ScratchBird.Data.Tests/JDBC203PoolingAndRecoveryContractTests.cs`

## Latest run
- Command:
  - `JDBC203_PROFILES=direct JDBC203_STRICT_GATE=false bash artifacts/enterprise-readiness/JDBC-203/run_cross_runtime_pool_contract.sh`
- Result:
  - direct profile passed for `.NET` and JDBC
  - `latest_verification.log` and `latest_contract_summary.json` updated with pass outcome and profile statuses.

## Remaining work
No code gap remains for JDBC-203 gate implementation. Runtime CI provisioning for additional profile endpoints (`manager`, `listener`) remains an environment/evidence task.

## Verification command

Direct profile:

```bash
JDBC203_PROFILES=direct \
JDBC203_STRICT_GATE=true \
bash artifacts/enterprise-readiness/JDBC-203/run_cross_runtime_pool_contract.sh
```

Profile matrix:

```bash
JDBC203_PROFILES=direct,manager,listener \
JDBC203_STRICT_GATE=true \
bash artifacts/enterprise-readiness/JDBC-203/run_cross_runtime_pool_contract.sh
```
