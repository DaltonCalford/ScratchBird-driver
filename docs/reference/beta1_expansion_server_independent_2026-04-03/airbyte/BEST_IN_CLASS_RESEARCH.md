# Airbyte Connector Best-In-Class Research

Status: Current
Lane: `airbyte`
Benchmark: `Airbyte PostgreSQL source/destination`

## Why This Benchmark

The PostgreSQL source and destination connectors define the expectation set for
how ScratchBird should participate in Airbyte-style replication and ingestion
workflows. They anchor:

- source incremental sync behavior
- destination load semantics
- state/checkpoint handling
- Airbyte protocol compatibility

## Official Sources

- PostgreSQL source docs:
  `https://docs.airbyte.com/integrations/sources/postgres`
- PostgreSQL destination docs:
  `https://docs.airbyte.com/integrations/destinations/postgres`
- Airbyte protocol docs:
  `https://docs.airbyte.com/platform/understanding-airbyte/airbyte-protocol`
- Implementation anchor:
  `https://github.com/airbytehq/airbyte`

## Capability Families That Become Non-Optional

- source and destination connector packaging
- connection checks, discovery, read, write, and state handling
- incremental sync and checkpoint compatibility
- schema/type mapping into Airbyte records and catalogs
- deployment/runtime expectations for connector containers

## ScratchBird Implementation Implications

- the lane needs both source-style and destination-style thinking, not just one
  half of the connector contract
- metadata and type fidelity matter because they shape downstream schema
  inference and sync correctness
- packaging and deployment format are part of the product contract

## Later Server Validation Focus

- connection checks and discovery
- source incremental sync and state persistence
- destination write correctness and idempotence
- container packaging and Airbyte platform registration
