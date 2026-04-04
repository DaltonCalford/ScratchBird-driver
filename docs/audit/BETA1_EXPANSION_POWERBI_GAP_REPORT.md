# Beta 1 Expansion Power BI Gap Report

Status: Current
Lane: `powerbi`
Benchmark: `Power BI PostgreSQL / ODBC custom connector surface`
Research packet: `docs/reference/beta1_expansion_server_independent_2026-04-03/powerbi/BEST_IN_CLASS_RESEARCH.md`

## Current ScratchBird Truth

- the lane is active Beta 1 authority
- the top-level compatibility spec and public docs exist
- implementation is not started
- no live proof exists yet

## Functional Gaps

- no Power Query connector or custom connector packaging exists yet
- no credential/connection dialog behavior is implemented yet
- no documented split exists yet between ODBC delegation and custom connector logic

## Metadata And Type Gaps

- no Power BI-specific type/folding rules are implemented yet
- no metadata-model projection contract exists yet
- no diagnostics contract exists yet for refresh/query failures

## Packaging And Tooling Gaps

- no `.mez` connector package exists yet
- no Power BI Desktop installation workflow or sample PBIX exists yet
- no host-version compatibility matrix exists yet

## Live-Proof-Only Gaps

- import/refresh behavior needs desktop proof
- folding behavior needs live testing
- credential and gateway behavior need live validation

## Offline Closure Target

Offline closure is achieved when the compatibility spec and public docs clearly
define the connector architecture, packaging targets, and live-only proof work.
