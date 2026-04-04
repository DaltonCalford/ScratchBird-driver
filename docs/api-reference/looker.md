# Looker API / Integration Reference

<!-- lane-status:start -->
## Current Status

- Lane kind: `adapter`
- Current state: `planned_beta1`
- Best-in-class benchmark: `Looker PostgreSQL dialect`
- Authoritative lane spec: `docs/application-reference/LOOKER_COMPATIBILITY_SPECIFICATION.md`
- Research packet: `docs/reference/beta1_expansion_server_independent_2026-04-03/looker/BEST_IN_CLASS_RESEARCH.md`
- Lane gap report: `docs/audit/BETA1_EXPANSION_LOOKER_GAP_REPORT.md`
- Remaining gap summary: The lane is specification-deepened and implementation-ready, but the dialect layer, deployment assets, and all live proof remain outstanding.
<!-- lane-status:end -->

## Planned Package Surface

- ScratchBird Looker dialect/deployment package
- underlying driver prerequisites documented by the lane
- release evidence root: `release/readiness/looker/<version>/`

## Mandatory Integration Surface

- connection and credential handling
- SQL/dialect behavior for Looker workloads
- metadata and type behavior for explores and SQL Runner
- PDT-friendly DDL and persistence rules

## Non-Optional Behaviors

- explicit documentation of dialect-versus-driver responsibilities
- deterministic metadata/type behavior
- documented PDT behavior and caveats

## Later Proof

- server verification packet: `docs/development/server-verification/looker.md`
- release evidence root: `release/readiness/looker/<version>/`

