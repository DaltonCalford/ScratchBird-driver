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

## `driver_closure_substrate.py`

Normalizes raw driver conformance output plus SQLSTATE coverage into a shared
PH5 closure summary and cross-driver matrix:

```bash
python3 scripts/driver_closure_substrate.py validate-contracts
python3 scripts/driver_closure_substrate.py summarize --driver-id go --lane alpha-primary \
  --conformance-results /tmp/go_conformance.json \
  --sqlstate-codes /tmp/go_sqlstates.json
python3 scripts/driver_closure_substrate.py matrix \
  --driver-summary /tmp/go_summary.json \
  --driver-summary /tmp/node_summary.json
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
