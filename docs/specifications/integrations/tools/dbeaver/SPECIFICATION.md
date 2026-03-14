# DBeaver Integration Specification

Status: Updated 2026-03-13
Priority: P0
Category: Database Tool

Canonical contract:

- `~/CliWork/local_work/docs/specifications/work/planning/SCRATCHBIRD_DBEAVER_ADAPTER_CONTRACT_2026-03-13.md`

## 1. Goal

Deliver first-class ScratchBird support in DBeaver while reusing the existing
ScratchBird JDBC driver.

This now means full DBeaver-native support across:

1. navigator and metadata browsing
2. SQL editor/autocomplete/formatter behavior
3. object create/edit/drop workflows
4. connection, auth, and TLS/network UX
5. value rendering and specialized data editors
6. operational tasks, tools, and related feature families where ScratchBird has
   real backing capability

## 2. Required Integration Path

1. DBeaver adapter source home:
   `tracks/alpha/integrations/scratchbird-dbeaver-driver/`
2. Transport/runtime layer:
   `tracks/p3/drivers/jdbc/`
3. Core DBeaver registration mechanism:
   `org.jkiss.dbeaver.dataSourceProvider`
4. Generic JDBC customization mechanism:
   `org.jkiss.dbeaver.generic.meta`
5. SQL editor specialization:
   `org.jkiss.dbeaver.sqlDialect`
6. Full native UX layer:
   companion ScratchBird UI plugin using DBeaver UI extension points

## 3. Required Adapter Features

1. Register `com.scratchbird.jdbc.SBDriver` as a DBeaver driver.
2. Provide a ScratchBird datasource provider derived from DBeaver generic JDBC.
3. Replace the inherited generic schema node with a recursive schema tree.
4. Inflate dotted ScratchBird schemas into nested navigator directories.
5. Register a ScratchBird SQL dialect for database-specific SQL editor behavior.
6. Provide object managers for supported ScratchBird object lifecycle actions.
7. Provide database editors/configurators for supported object families.
8. Provide ScratchBird-specific connection/auth/network UI as needed.
9. Provide value handlers/managers for ScratchBird-specific type behavior.
10. Wire supported tasks/tools/dashboards/generators where ScratchBird has real
    backing capability.
11. Preserve generic folders for tables, views, and data types unless they are
    intentionally replaced.
12. Build a stock-installable p2 update site.
13. Support installation into a DBeaver source checkout without duplicate patch
   lines on rerun.

## 4. Recursive Schema Contract

1. `users.alice.dev` must render as `users -> alice -> dev`.
2. Parent segments are reconstructed client-side in the DBeaver adapter.
3. `sys` and `sys.*` remain identifiable as system schemas.
4. Recursive directories are a navigator-tree concern, not a DBeaver
   filesystem-provider concern.

## 5. SQL Editor Requirements

1. ScratchBird scripts must bind to a ScratchBird dialect rather than generic
   SQL where DBeaver supports dialect-specific behavior.
2. Autocomplete and related SQL editor behavior must use ScratchBird-specific
   keyword/type/function rules.
3. If DBeaver requires dialect adapter factories for parser/text-rule support,
   ScratchBird must supply them.

## 6. JDBC-Side Requirements

1. JDBC metadata must expose stable schema names and generic metadata coverage.
2. Optional property `metadataExpandSchemaParents` may emit parent schema rows,
   but the adapter must function without it.
3. JDBC changes made solely for DBeaver should be kept minimal unless they
   benefit other recursive-schema consumers.

## 7. Full-Native Scope Rules

1. Any DBeaver feature family ScratchBird cannot back correctly should be
   hidden, not exposed as partially broken.
2. Complete support does not mean implementing every DBeaver extension point in
   the abstract; it means implementing every relevant feature family that maps
   to real ScratchBird capability.

## 6. Performance Expectations

- Avoid per-row allocations in hot loops.
- Use buffered I/O for network reads and writes.
- Support prepared statement reuse and pooled connections.

## 7. Compatibility Notes

- Validate SQL dialect assumptions with ScratchBird.
- Ensure parameter binding uses SBWP binary-only encoding.

## 8. Testing

- Unit tests for encode/decode of all wire types.
- Integration tests against live ScratchBird server.
- Conformance harness integration where applicable.
- Metadata contract validation tests for sys.* queries.


## 10. System Constraints & Vendor Quirks

- DBeaver relies on JDBC drivers and expects a JDBC URL for connections.
- Driver registration and classpath loading must work with custom driver jars.
- Metadata queries must be efficient to avoid UI timeouts.

## 11. Code Examples

```properties
# DBeaver JDBC URL
jdbc:scratchbird://localhost:3092/db
```

## 12. Vendor-Specific Test Criteria

- Validate schema browser loads tables, columns, and indexes.
- Confirm DBeaver can generate and execute `SELECT` previews.

## 13. Implementation Checklist Appendix

- Driver checklist: `docs/planning/driver-checklists/jdbc.md`
- [ ] Constraint: DBeaver relies on JDBC drivers and expects a JDBC URL for connections. (Driver task: `docs/planning/driver-checklists/jdbc.md`)
- [ ] Constraint: Driver registration and classpath loading must work with custom driver jars. (Driver task: `docs/planning/driver-checklists/jdbc.md`)
- [ ] Constraint: Metadata queries must be efficient to avoid UI timeouts. (Driver task: `docs/planning/driver-checklists/jdbc.md`)
- [ ] Test: Validate schema browser loads tables, columns, and indexes. (Driver task: `docs/planning/driver-checklists/jdbc.md`)
- [ ] Test: Confirm DBeaver can generate and execute `SELECT` previews. (Driver task: `docs/planning/driver-checklists/jdbc.md`)

## 14. References

- docs/specifications/NATIVE_PROTOCOL_ALIGNMENT.md
- docs/specifications/TYPE_MAPPING_MATRIX.md
- docs/specifications/DRIVER_ERROR_MAPPING.md
- docs/specifications/DRIVER_METADATA_JDBC_ODBC_MAPPING.md
- docs/specifications/METADATA_SCHEMA_CONTRACT.md
- docs/specifications/DRIVER_PARAMETER_ENCODING.md
- docs/specifications/DRIVER_RESULT_DECODING.md
- docs/specifications/DRIVER_STREAMING_AND_PAGING.md
- docs/specifications/DRIVER_THREAD_SAFETY_POOLING.md
- docs/specifications/DRIVER_CANCELLATION_TIMEOUTS.md
- docs/specifications/DRIVER_DSN_AND_CONFIG_STANDARD.md
