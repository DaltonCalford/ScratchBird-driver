# Native Parser Migration Status (Driver Repo)

Date: 2026-02-18  
Scope: `ScratchBird-driver` tracks `alpha`, `beta`, and `p3` drivers

## Execution Boundary Rules (Confirmed)

1. Engine execution boundary is `ServerSession` only:
   - `ScratchBird/src/server/server_session.cpp:793`
   - `ScratchBird/src/server/server_session.cpp:815`
   - `ScratchBird/src/server/server_session.cpp:818`
   - `ScratchBird/src/server/server_session.cpp:979`
2. `native_adapter` is protocol/parser translation and forwarding:
   - `ScratchBird/src/protocol/adapters/native_adapter.cpp:2011`
   - `ScratchBird/src/protocol/adapters/native_adapter.cpp:2030`
   - `ScratchBird/src/protocol/adapters/native_adapter.cpp:2040`
   - `ScratchBird/src/protocol/adapters/protocol_adapter.cpp:532`
   - `ScratchBird/src/protocol/adapters/protocol_adapter.cpp:589`
3. Operational rule:
   - No SQL text execution path inside server/executor.
   - SQL must be compiled to SBLR before submission.
   - One dialect parser per configured port; no parser protocol auto-detect fallback.

## Remediation Applied (2026-02-18 pass)

1. Harness contract moved to native-parser-first naming and requirements:
   - `docs/specifications/DRIVER_CONFORMANCE_TEST_HARNESS.md`
   - `docs/fixtures/sbwp_conformance_manifest.json`
   - `tracks/p3/drivers/go/conformance/harness.go` (kind aliases for `native_query` and `native_prepare_bind`)
2. C++ core driver now enforces native parser endpoint selection in config parsing/connect:
   - `tracks/p3/drivers/cpp/include/scratchbird/client/network_client.h`
   - `tracks/p3/drivers/cpp/src/driver_config.cpp`
   - `tracks/p3/drivers/cpp/src/network_client.cpp`
3. ODBC now validates and normalizes `protocol=native` during DSN parsing and connect:
   - `tracks/p3/drivers/odbc/src/odbc_handles.cpp`
   - `tracks/p3/drivers/odbc/src/odbc_client_bridge.cpp`
4. `sb_isql` parser option no longer switches parser dialects at runtime (`SET PARSER` removed in startup flow):
   - `tracks/p3/drivers/cli/sb_isql.cpp`
   - `docs/user-documentation/tools/sb-isql.md`
   - `wiki/cli-tools/sb-isql.md`
5. Pascal TLS specification added for in-repo implementation (not TaurusTLS code reuse):
   - `docs/specifications/drivers/language/pascal-delphi/TLS_IMPLEMENTATION_SPEC.md`
6. Native parser endpoint enforcement added across downstream driver configs/connect paths:
   - Alpha: Go, Node, Python, Rust, Ruby, PHP, Pascal, .NET, JDBC
   - Beta/P3: Dart, Swift, R, Elixir
   - Mojo: native protocol validation in config + connect path

## Current Driver Status Summary

Global status: **native parser endpoint selection is now enforced in all tracked drivers; still not bytecode-first for default query APIs**.

Observed pattern:
- Most drivers send SQL text through `QUERY` in normal query methods.
- Many drivers expose explicit SBLR APIs, but as opt-in paths.
- Driver query flag definitions still use `0x10` as `RETURN_SBLR`; engine protocol uses `0x10` for `BYTECODE`.

Engine flag reference:
- `ScratchBird/include/scratchbird/protocol/wire_protocol.h:340`
- `ScratchBird/include/scratchbird/protocol/wire_protocol.h:341`

## Driver Matrix

Legend:
- `SQL QUERY default`: standard query API submits SQL text via `QUERY`.
- `SBLR API`: explicit SBLR execution API exists.
- `Bytecode flag aligned`: driver-side query flags align `0x10` with bytecode semantics.

| Driver | SQL QUERY default | SBLR API | Bytecode flag aligned | Evidence |
|---|---|---|---|---|
| Go | Yes | Yes | No | `tracks/p3/drivers/go/conn.go:532`, `tracks/p3/drivers/go/conn.go:546`, `tracks/p3/drivers/go/conn.go:717`, `tracks/p3/drivers/go/protocol.go:126` |
| Node | Yes | Yes | No | `tracks/p3/drivers/node/src/client.ts:890`, `tracks/p3/drivers/node/src/client.ts:899`, `tracks/p3/drivers/node/src/client.ts:473`, `tracks/p3/drivers/node/src/protocol.ts:126` |
| Python | Yes | Yes | No | `tracks/p3/drivers/python/src/scratchbird/connection.py:648`, `tracks/p3/drivers/python/src/scratchbird/connection.py:651`, `tracks/p3/drivers/python/src/scratchbird/connection.py:403`, `tracks/p3/drivers/python/src/scratchbird/protocol.py:138` |
| Rust | Yes | Yes | No | `tracks/p3/drivers/rust/src/client.rs:919`, `tracks/p3/drivers/rust/src/client.rs:924`, `tracks/p3/drivers/rust/src/client.rs:395`, `tracks/p3/drivers/rust/src/protocol.rs:110` |
| Ruby | Yes | Yes | No | `tracks/p3/drivers/ruby/lib/scratchbird/client.rb:625`, `tracks/p3/drivers/ruby/lib/scratchbird/client.rb:637`, `tracks/p3/drivers/ruby/lib/scratchbird/client.rb:180`, `tracks/p3/drivers/ruby/lib/scratchbird/protocol.rb:121` |
| PHP | Yes | Yes | No | `tracks/p3/drivers/php/src/Connection.php:611`, `tracks/p3/drivers/php/src/Connection.php:616`, `tracks/p3/drivers/php/src/Connection.php:190`, `tracks/p3/drivers/php/src/Protocol.php:128` |
| .NET | Yes | Yes | No | `tracks/p3/drivers/dotnet/src/ScratchBird.Data/ProtocolClient.cs:379`, `tracks/p3/drivers/dotnet/src/ScratchBird.Data/ProtocolClient.cs:383`, `tracks/p3/drivers/dotnet/src/ScratchBird.Data/ProtocolClient.cs:192`, `tracks/p3/drivers/dotnet/src/ScratchBird.Data/WireProtocol.cs:134` |
| JDBC | Yes | Yes | No | `tracks/p3/drivers/jdbc/src/main/java/com/scratchbird/jdbc/SBProtocolHandler.java:832`, `tracks/p3/drivers/jdbc/src/main/java/com/scratchbird/jdbc/SBProtocolHandler.java:838`, `tracks/p3/drivers/jdbc/src/main/java/com/scratchbird/jdbc/SBProtocolHandler.java:465`, `tracks/p3/drivers/jdbc/src/main/java/com/scratchbird/jdbc/SBProtocolHandler.java:203` |
| Pascal | Yes | Yes | No | `tracks/p3/drivers/pascal/src/ScratchBird.Client.pas:1071`, `tracks/p3/drivers/pascal/src/ScratchBird.Client.pas:1083`, `tracks/p3/drivers/pascal/src/ScratchBird.Client.pas:487`, `tracks/p3/drivers/pascal/src/ScratchBird.Protocol.pas:141` |
| C++ core | Yes | Yes | No | `tracks/p3/drivers/cpp/src/network_client.cpp:777`, `tracks/p3/drivers/cpp/src/network_client.cpp:783`, `tracks/p3/drivers/cpp/src/network_client.cpp:1368`, `tracks/p3/drivers/cpp/include/scratchbird/protocol/sbwp_protocol.h:116` |
| ODBC | Yes | No (bridge API) | No (inherits C++) | `tracks/p3/drivers/odbc/src/odbc_client_bridge.cpp:157`, `tracks/p3/drivers/odbc/src/odbc_client_bridge.cpp:167` |
| CLI tools | Yes | No | Partial (`wire_protocol` copy only) | `tracks/p3/drivers/cli/sb_isql.cpp:1559`, `tracks/p3/drivers/cli/sbdriver_conformance.cpp:722`, `tracks/p3/drivers/cli/include/scratchbird/protocol/wire_protocol.h:340` |
| Dart | Yes | Yes | No | `tracks/p3/drivers/dart/lib/src/client.dart:391`, `tracks/p3/drivers/dart/lib/src/client.dart:395`, `tracks/p3/drivers/dart/lib/src/client.dart:254`, `tracks/p3/drivers/dart/lib/src/protocol.dart:91` |
| Swift | Yes | Yes | No | `tracks/p3/drivers/swift/Sources/ScratchBird/Connection.swift:381`, `tracks/p3/drivers/swift/Sources/ScratchBird/Connection.swift:386`, `tracks/p3/drivers/swift/Sources/ScratchBird/Connection.swift:251`, `tracks/p3/drivers/swift/Sources/ScratchBird/Protocol.swift:113` |
| R | Yes | Yes | No | `tracks/p3/drivers/r/R/client.R:475`, `tracks/p3/drivers/r/R/client.R:480`, `tracks/p3/drivers/r/R/client.R:177`, `tracks/p3/drivers/r/R/protocol.R:119` |
| Elixir (p3) | Yes | Yes | No | `tracks/p3/drivers/elixir/lib/scratchbird/connection.ex:364`, `tracks/p3/drivers/elixir/lib/scratchbird/connection.ex:369`, `tracks/p3/drivers/elixir/lib/scratchbird/connection.ex:192`, `tracks/p3/drivers/elixir/lib/scratchbird/protocol.ex:120` |
| Mojo | Yes | No | No | `tracks/p3/drivers/mojo/src/scratchbird.mojo:1309`, `tracks/p3/drivers/mojo/src/scratchbird.mojo:1317`, `tracks/p3/drivers/mojo/src/scratchbird.mojo:812` |

## Additional Observations

1. Driver docs/planning are stale or conflicting in places:
   - `docs/planning/driver-checklists/dart.md:7` vs `docs/planning/ISSUE_INDEX.md:12`
   - `docs/planning/driver-checklists/swift.md:7` vs `docs/planning/ISSUE_INDEX.md:65`
2. Conformance contract now uses native-parser-first kinds; some adapters still rely on legacy aliases:
   - `docs/fixtures/sbwp_conformance_manifest.json:13`
   - `docs/specifications/DRIVER_CONFORMANCE_TEST_HARNESS.md:44`
   - `tracks/p3/drivers/go/conformance/harness.go:436`
3. Native protocol alignment doc still describes unparameterized SQL `QUERY`:
   - `docs/specifications/NATIVE_PROTOCOL_ALIGNMENT.md:33`

## Remediation Order

### Phase 1: Shared Protocol Contract

1. Align driver query flag definitions with engine bytecode semantics (`0x10`/`0x20`).
2. Introduce common behavior in each driver:
   - `query(sql)` must compile via native parser endpoint, then submit bytecode `QUERY`.
   - keep explicit SBLR APIs for precompiled/reused bytecode.

### Phase 2: Core Library First

1. Update C++ core (`tracks/p3/drivers/cpp/`) to become reference implementation.
2. Migrate ODBC + CLI to consume new bytecode-first C++ query path.

### Phase 3: Language Drivers

1. Alpha drivers: Go, Node, Python, Rust, Ruby, PHP, .NET, JDBC, Pascal.
2. Beta/P3 drivers: Dart, Swift, R, Elixir.
3. Mojo: add explicit native-parser compile + bytecode submit flow (currently SQL `QUERY` only).

### Phase 4: Conformance + Docs

1. Expand native-parser conformance checks from naming/contract to strict runtime enforcement tests.
2. Add tests that fail on SQL-text `QUERY` usage in standard query APIs.
3. Reconcile planning docs against source-of-truth matrix.
