# Beta 1 Expansion Airbyte Gap Report

Status: Current
Lane: `airbyte`
Benchmark: `Airbyte PostgreSQL source/destination`
Research packet: `docs/reference/beta1_expansion_server_independent_2026-04-03/airbyte/BEST_IN_CLASS_RESEARCH.md`

## Current ScratchBird Truth

- the lane is active Beta 1 authority
- the top-level compatibility spec and public docs exist
- implementation is not started
- no live proof exists yet

## Functional Gaps

- no Airbyte source connector exists yet
- no Airbyte destination connector exists yet
- no discovery, state, incremental sync, or write contract is implemented yet

## Metadata And Type Gaps

- no Airbyte catalog/type mapping exists yet
- no state/checkpoint mapping is implemented yet
- no schema evolution behavior has been specified in code or tests

## Packaging And Tooling Gaps

- no connector packaging or containerization exists yet
- no Airbyte platform registration guidance exists yet
- no connector acceptance-test plan exists yet

## Live-Proof-Only Gaps

- source discovery and incremental sync need live validation
- destination write correctness and idempotence need live validation
- container/runtime proof must be collected against a working server

## Offline Closure Target

Offline closure is achieved when the connector specs and public docs fully
describe both source and destination behavior, packaging, and later proof steps.
