# Beta 1 Expansion Looker Gap Report

Status: Current
Lane: `looker`
Benchmark: `Looker PostgreSQL dialect`
Research packet: `docs/reference/beta1_expansion_server_independent_2026-04-03/looker/BEST_IN_CLASS_RESEARCH.md`

## Current ScratchBird Truth

- the lane is active Beta 1 authority
- the top-level compatibility spec and public docs exist
- implementation is not started
- no live proof exists yet

## Functional Gaps

- no Looker dialect/connection package exists yet
- no documented PDT-safe behavior is implemented yet
- no SQL Runner, explore, or LookML-oriented validation path exists yet

## Metadata And Type Gaps

- no Looker-specific type mapping or dialect capability table exists yet
- no PDT/temporary-object behavior contract exists yet in code or tests
- no diagnostics contract exists yet for Looker connection/runtime failures

## Packaging And Tooling Gaps

- no deployment/driver packaging guidance exists yet for Looker runtimes
- no example connection settings or sample models exist yet
- no compatibility matrix exists for supported Looker releases

## Live-Proof-Only Gaps

- connection bootstrap and query execution need live Looker validation
- PDT creation/refresh needs live proof
- SQL/dialect behavior must be proven in real LookML workflows

## Offline Closure Target

Offline closure is achieved when the compatibility spec and public docs fully
spell out the dialect contract, PDT behavior, packaging, and later proof steps.
