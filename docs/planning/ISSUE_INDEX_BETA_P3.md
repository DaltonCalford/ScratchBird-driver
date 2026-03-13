# Beta/P3 Deferred Issue Index

Maps deferred Beta/P3 issue stubs to checklist line anchors.

- Constraint: Provide a stable C API façade for language bindings where ABI stability is required. (Sources: `docs/specifications/integrations/drivers/cpp/SPECIFICATION.md`) -> `docs/planning/driver-checklists/cpp.md#L19`
- Constraint: Support both static and shared builds with explicit linkage flags. (Sources: `docs/specifications/integrations/drivers/cpp/SPECIFICATION.md`) -> `docs/planning/driver-checklists/cpp.md#L20`
- Constraint: Document ownership of buffers returned to callers. (Sources: `docs/specifications/integrations/drivers/cpp/SPECIFICATION.md`) -> `docs/planning/driver-checklists/cpp.md#L21`
- Test: Verify both static and shared builds link successfully. (Sources: `docs/specifications/integrations/drivers/cpp/SPECIFICATION.md`) -> `docs/planning/driver-checklists/cpp.md#L22`
- Test: Validate row buffers remain valid until the next fetch call. (Sources: `docs/specifications/integrations/drivers/cpp/SPECIFICATION.md`) -> `docs/planning/driver-checklists/cpp.md#L23`
- Add SQLSTATE class-prefix mapping (currently only prefixes message) in `tracks/p3/drivers/r/R/client.R`. -> `docs/planning/driver-checklists/r.md#L6`
- Add conformance tests for full type matrix in `tracks/p3/drivers/r/tests/`. -> `docs/planning/driver-checklists/r.md#L10`
- Constraint: Conform to R DBI generics and return data frames with stable column classes. (Sources: `docs/specifications/integrations/drivers/r/SPECIFICATION.md`) -> `docs/planning/driver-checklists/r.md#L16`
- Constraint: Support `dbListTables` and `dbColumnInfo` for metadata introspection. (Sources: `docs/specifications/integrations/drivers/r/SPECIFICATION.md`) -> `docs/planning/driver-checklists/r.md#L17`
- Constraint: Treat `NA` and `NULL` per DBI expectations. (Sources: `docs/specifications/integrations/drivers/r/SPECIFICATION.md`) -> `docs/planning/driver-checklists/r.md#L18`
- Test: Validate `dbGetQuery` returns consistent `data.frame` column types. (Sources: `docs/specifications/integrations/drivers/r/SPECIFICATION.md`) -> `docs/planning/driver-checklists/r.md#L19`
- Test: Ensure `dbBind` supports positional and named parameters. (Sources: `docs/specifications/integrations/drivers/r/SPECIFICATION.md`) -> `docs/planning/driver-checklists/r.md#L20`
