# ScratchBird-driver convenience targets

MOJO_TEST_DIR := "tracks/alpha/drivers/mojo/tests"
MOJO_MANIFEST := "docs/fixtures/sbwp_conformance_manifest.json"

mojo-conformance:
    PATH="{{pwd}}/{{MOJO_TEST_DIR}}:{{env_var_or_default("PATH", "")}}" sbdriver-conformance --manifest {{MOJO_MANIFEST}}

mojo-integration:
    PATH="{{pwd}}/{{MOJO_TEST_DIR}}:{{env_var_or_default("PATH", "")}}" mojo {{MOJO_TEST_DIR}}/integration.mojo
