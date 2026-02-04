# ScratchBird-driver convenience targets

MOJO_TEST_DIR := tracks/alpha/drivers/mojo/tests
MOJO_MANIFEST ?= docs/fixtures/sbwp_conformance_manifest.json

.PHONY: mojo-conformance
mojo-conformance:
	PATH="$(PWD)/$(MOJO_TEST_DIR):$$PATH" sbdriver-conformance --manifest $(MOJO_MANIFEST)

.PHONY: mojo-integration
mojo-integration:
	PATH="$(PWD)/$(MOJO_TEST_DIR):$$PATH" mojo $(MOJO_TEST_DIR)/integration.mojo
