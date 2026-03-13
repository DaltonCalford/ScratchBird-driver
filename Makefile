# ScratchBird-driver convenience targets

MOJO_TEST_DIR := tracks/p3/drivers/mojo/tests
MOJO_MANIFEST ?= docs/fixtures/sbwp_conformance_manifest.json

.PHONY: mojo-conformance
mojo-conformance:
	PATH="$(PWD)/$(MOJO_TEST_DIR):$$PATH" sbdriver-conformance --manifest $(MOJO_MANIFEST)

.PHONY: mojo-integration
mojo-integration:
	PATH="$(PWD)/$(MOJO_TEST_DIR):$$PATH" mojo $(MOJO_TEST_DIR)/integration.mojo

.PHONY: runtime-up
runtime-up:
	./scripts/driver_runtime_stack.sh up

.PHONY: runtime-down
runtime-down:
	./scripts/driver_runtime_stack.sh down

.PHONY: runtime-status
runtime-status:
	./scripts/driver_runtime_stack.sh status

.PHONY: runtime-fixtures
runtime-fixtures:
	./scripts/driver_runtime_stack.sh fixtures

.PHONY: runtime-jdbc-odbc
runtime-jdbc-odbc:
	./scripts/run_jdbc_odbc_runtime_checks.sh
