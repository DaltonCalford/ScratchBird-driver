# ScratchBird-driver Scripts

## `driver_runtime_stack.sh`

Starts/stops ScratchBird runtime stack for driver integration against real
server + parser + listener components.

Examples:

```bash
scripts/driver_runtime_stack.sh up
scripts/driver_runtime_stack.sh fixtures
eval "$(scripts/driver_runtime_stack.sh env)"
scripts/driver_runtime_stack.sh status
scripts/driver_runtime_stack.sh down
```

## `run_jdbc_odbc_runtime_checks.sh`

Runs JDBC and ODBC validation against a live runtime stack:

```bash
scripts/run_jdbc_odbc_runtime_checks.sh
```

## `artifacts/enterprise-readiness/JDBC-203/run_cross_runtime_pool_contract.sh`

Runs the JDBC-203 cross-runtime pooling/recovery gate for .NET + JDBC.
The .NET phase executes each contract case in isolation and refreshes the
runtime stack between cases for deterministic verification.

```bash
scripts/driver_runtime_stack.sh refresh --mode static
eval "$(scripts/driver_runtime_stack.sh env --mode static)"
artifacts/enterprise-readiness/JDBC-203/run_cross_runtime_pool_contract.sh
```
