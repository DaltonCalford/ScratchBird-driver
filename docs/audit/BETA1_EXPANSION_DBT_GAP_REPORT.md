# Beta 1 Expansion dbt Gap Report

Status: Current
Lane: `dbt`
Benchmark: `dbt-postgres`
Research packet: `docs/reference/beta1_expansion_server_independent_2026-04-03/dbt/BEST_IN_CLASS_RESEARCH.md`

## Current ScratchBird Truth

- the lane is active Beta 1 authority
- the top-level compatibility spec and public docs exist
- implementation is not started
- no live proof exists yet

## Functional Gaps

- no dbt adapter package exists yet
- no materialization macros, adapter plugin, or connection manager exists yet
- no seeds, snapshots, docs, tests, or relation-caching behavior exists yet

## Metadata And Type Gaps

- no quoting/schema naming rules are implemented yet
- no introspection contract exists for dbt docs/tests/catalog behavior
- no adapter type-mapping and relation metadata layer exists yet

## Packaging And Tooling Gaps

- no pip/package distribution exists yet
- no dbt-core compatibility matrix exists yet
- no CI or example project exists yet for the adapter

## Live-Proof-Only Gaps

- materialization correctness requires live dbt runs
- snapshots, seeds, tests, and docs generation need live validation
- performance and retry behavior need real-server proof

## Offline Closure Target

Offline closure is achieved when the adapter spec and public docs spell out the
dbt package layout, materialization contract, metadata rules, and later proof
commands.
