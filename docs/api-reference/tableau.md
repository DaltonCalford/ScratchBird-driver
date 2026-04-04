# Tableau API / Integration Reference

<!-- lane-status:start -->
## Current Status

- Lane kind: `adapter`
- Current state: `planned_beta1`
- Best-in-class benchmark: `Tableau PostgreSQL / Named Connector SDK`
- Authoritative lane spec: `docs/application-reference/TABLEAU_COMPATIBILITY_SPECIFICATION.md`
- Research packet: `docs/reference/beta1_expansion_server_independent_2026-04-03/tableau/BEST_IN_CLASS_RESEARCH.md`
- Lane gap report: `docs/audit/BETA1_EXPANSION_TABLEAU_GAP_REPORT.md`
- Remaining gap summary: The lane is specification-deepened and implementation-ready, but the connector, packaging, and all live proof remain outstanding.
<!-- lane-status:end -->

## Planned Package Surface

- ScratchBird Tableau connector package where required
- underlying driver prerequisites as documented by the lane
- release evidence root: `release/readiness/tableau/<version>/`

## Mandatory Integration Surface

- auth and connection bootstrap
- metadata discovery and capability declarations
- live query and extract behavior
- diagnostics and operational guidance

## Non-Optional Behaviors

- explicit documentation of native connector-versus-generic connectivity strategy
- deterministic metadata/type behavior
- packaging suitable for supported Tableau environments

## Later Proof

- server verification packet: `docs/development/server-verification/tableau.md`
- release evidence root: `release/readiness/tableau/<version>/`

