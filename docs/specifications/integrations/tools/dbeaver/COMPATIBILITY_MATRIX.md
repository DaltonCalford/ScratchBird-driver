# DBeaver Compatibility Matrix

Status: Updated 2026-03-13
Priority: P0

Canonical exhaustive matrix:
`local_work/docs/specifications/work/planning/SCRATCHBIRD_DBEAVER_EXHAUSTIVE_CAPABILITY_MATRIX_2026-03-13.md`

This repo-local file remains the compact implementation summary. The canonical
release-quality coverage map lives in the shared `local_work` planning tree.

| Capability | Required | Status | Notes |
| --- | --- | --- | --- |
| ScratchBird datasource provider plugin | Yes | Implemented | `org.jkiss.dbeaver.ext.scratchbird` plugin exists in the tracked integration lane. |
| ScratchBird generic meta-model binding | Yes | Implemented | Bound to `com.scratchbird.jdbc.SBDriver`. |
| Recursive schema-directory navigation | Yes | Implemented | Dotted schemas inflate to nested nodes in the adapter model. |
| Generic table/view/data-type browsing under schemas | Yes | Implemented | Provided through tree injection plus generic folder types. |
| ScratchBird SQL dialect | Yes | Missing | Needed for database-specific autocomplete/editor behavior. |
| Dialect adapter/rule-provider wiring | Likely yes | Missing | MySQL/Oracle use dialect adapters for parser/text rules. |
| ScratchBird UI plugin | Yes | Missing | Needed for full native DBeaver UX. |
| Object managers | Yes | Missing | Needed for create/edit/drop flows. |
| Database editors/configurators | Yes | Missing | Needed for source, DDL, property pages, and object dialogs. |
| Connection wizard/editor pages | Yes | Missing | Generic connection flow is not sufficient for full native support. |
| Auth/network/property configurators | Yes | Missing | Needed for ScratchBird-specific TLS/auth UX. |
| Data type providers and value managers | Yes | Missing | Needed for ScratchBird-specific type rendering/editing. |
| Tasks/tools integration | As applicable | Missing | Implement only for real ScratchBird operational capabilities. |
| Dashboard/generator/backup integrations | As applicable | Missing | Implement only where ScratchBird has real backing semantics. |
| Stock-installable p2 update-site packaging | Yes | Implemented | Tycho reactor, feature, repository, and zip builder are present. |
| Source-checkout install flow | Yes | Partial | Script exists; idempotency tightened, but a clean rerun against a normalized DBeaver checkout is still pending. |
| JDBC parent-schema metadata expansion | Optional | Implemented | Available via `metadataExpandSchemaParents`. |
