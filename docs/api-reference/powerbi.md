# Power BI API / Integration Reference

<!-- lane-status:start -->
## Current Status

- Lane kind: `adapter`
- Current state: `planned_beta1`
- Best-in-class benchmark: `Power BI PostgreSQL / ODBC custom connector surface`
- Authoritative lane spec: `docs/application-reference/POWERBI_COMPATIBILITY_SPECIFICATION.md`
- Research packet: `docs/reference/beta1_expansion_server_independent_2026-04-03/powerbi/BEST_IN_CLASS_RESEARCH.md`
- Lane gap report: `docs/audit/BETA1_EXPANSION_POWERBI_GAP_REPORT.md`
- Remaining gap summary: The lane is specification-deepened and implementation-ready, but the connector, packaging, and all live proof remain outstanding.
<!-- lane-status:end -->

## Planned Package Surface

- ScratchBird Power Query / Power BI connector package
- optional underlying ODBC dependency path where required
- release evidence root: `release/readiness/powerbi/<version>/`

## Mandatory Integration Surface

- credential and connection UX
- metadata and type projection into the model
- refresh behavior and diagnostics
- folding strategy and documented caveats

## Non-Optional Behaviors

- explicit documentation of connector-versus-ODBC responsibilities
- deterministic type/metadata behavior
- packaging suitable for Desktop/gateway installation

## Later Proof

- server verification packet: `docs/development/server-verification/powerbi.md`
- release evidence root: `release/readiness/powerbi/<version>/`

