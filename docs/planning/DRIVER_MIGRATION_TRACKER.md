# Driver Migration Tracker (ScratchBird -> ScratchBird-driver)

Status: In Progress
Last Updated: 2026-01-30

## Scope

Move all driver code/specs/wiki from the ScratchBird repo into
ScratchBird-driver, then bring the migrated drivers to full SBWP v1.1 parity.

## Migration Tasks

### Code Moves

- [ ] Move C/C++ client library (`libscratchbird_client`) into `cpp/` (sources + headers)
- [ ] Move C API wrapper (`scratchbird_client_c.*`) into `cpp/` and expose shared lib build
- [ ] Move ODBC driver (`scratchbird_odbc`) into `odbc/` (sources + headers)
- [ ] Move CLI clients (`sb_isql`, `sb_fb_isql`, `sb_pg_isql`, `sb_my_isql`, `sbdriver-conformance`) into `cli/`
- [ ] Move ODBC test suite into `odbc/tests/` (unit + integration)
- [ ] Add build system for C/ODBC/CLI (CMake + install targets)
- [ ] Remove moved code from ScratchBird and update its build references

### Documentation Moves

- [x] Move driver specs from ScratchBird `docs/specifications/drivers/` to ScratchBird-driver
- [x] Move `docs/specifications/api/CLIENT_LIBRARY_API_SPECIFICATION.md`
- [x] Move connectivity docs (`odbc.md`, `jdbc.md`, `sb-isql.md`) into ScratchBird-driver
- [x] Move ScratchBird wiki driver pages (CLI + ODBC/JDBC) into ScratchBird-driver wiki
- [x] Update ScratchBird docs to reference new driver locations

## SBWP v1.1 Parity Tasks

### C/C++ Client Library

- [ ] Support PARAMETER_STATUS for `attachment_id`/`current_txn_id`
- [ ] Track `last_query_sequence` for CANCEL
- [ ] Implement SET_OPTION wire call
- [ ] Implement PING/PONG handling
- [ ] Implement SUBSCRIBE/UNSUBSCRIBE for notifications
- [ ] Implement QUERY_PLAN and SBLR_COMPILED handlers
- [ ] Implement SBLR_EXECUTE (bytecode path + hash-only path)
- [ ] Implement STREAM_CONTROL for server-driven streams
- [ ] Implement ATTACH_CREATE/DETACH/LIST (emulation)

### ODBC Driver

- [ ] Pass-through SET_OPTION for driver attributes
- [ ] Attach emulation controls via SQLSetConnectAttr
- [ ] Expose SUBSCRIBE/UNSUBSCRIBE via driver extensions
- [ ] Support SBLR_EXECUTE for prepared statements (optional extension)
- [ ] Honor server QUERY_PLAN/SBLR_COMPILED for diagnostics
- [ ] Ensure CANCEL uses query sequence id

### CLI Clients

- [ ] Expose SET OPTION / SHOW OPTION commands (native)
- [ ] Add `\subscribe` / `\unsubscribe` meta-commands
- [ ] Add `\plan` hooks to display QUERY_PLAN payloads
- [ ] Add `\sblr` hooks to display SBLR_COMPILED payloads

## Open Questions

- Should ScratchBird keep an internal `scratchbird_client` for parser/server use,
  or should parsers link against the driver repo copy?
- Which SBWP v1.1 features should be exposed via public ODBC extensions?
