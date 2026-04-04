# Beta 1 Expansion Tableau Gap Report

Status: Current
Lane: `tableau`
Benchmark: `Tableau PostgreSQL / Named Connector SDK`
Research packet: `docs/reference/beta1_expansion_server_independent_2026-04-03/tableau/BEST_IN_CLASS_RESEARCH.md`

## Current ScratchBird Truth

- the lane is active Beta 1 authority
- the top-level compatibility spec and public docs exist
- implementation is not started
- no live proof exists yet

## Functional Gaps

- no Tableau connector package exists yet
- no capability declaration, auth, or metadata integration exists yet
- no live/extract validation path exists yet

## Metadata And Type Gaps

- no relation/type mapping table exists yet for Tableau expectations
- no capability-flag contract exists yet
- no diagnostics/connector logging behavior exists yet

## Packaging And Tooling Gaps

- no Tableau connector artifact exists yet
- no installation/setup workflow or sample workbook exists yet
- no host-version compatibility matrix exists yet

## Live-Proof-Only Gaps

- live/extract behavior needs real Tableau validation
- metadata browse and refresh flows need live proof
- connector packaging/install proof must be performed in Tableau environments

## Offline Closure Target

Offline closure is achieved when the compatibility spec and public docs fully
define connector capabilities, packaging, and later proof commands.
