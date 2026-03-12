# ScratchBird-driver convenience targets

MOJO_TEST_DIR := "tracks/alpha/drivers/mojo/tests"
MOJO_MANIFEST := "docs/fixtures/sbwp_conformance_manifest.json"

mojo-conformance:
    PATH="{{pwd}}/{{MOJO_TEST_DIR}}:{{env_var_or_default("PATH", "")}}" sbdriver-conformance --manifest {{MOJO_MANIFEST}}

mojo-integration:
    PATH="{{pwd}}/{{MOJO_TEST_DIR}}:{{env_var_or_default("PATH", "")}}" mojo {{MOJO_TEST_DIR}}/integration.mojo

runtime-up:
    ./scripts/driver_runtime_stack.sh up

runtime-down:
    ./scripts/driver_runtime_stack.sh down

runtime-status:
    ./scripts/driver_runtime_stack.sh status

runtime-fixtures:
    ./scripts/driver_runtime_stack.sh fixtures

runtime-jdbc-odbc:
    ./scripts/run_jdbc_odbc_runtime_checks.sh

driver-closure-validate:
    python3 scripts/driver_closure_substrate.py validate-contracts
