# Driver Server-Blocked Remaining Work

    Status: Current
    Last Updated: 2026-04-03

    This report captures the remaining work that still requires a working
    ScratchBird test server after the server-independent completion pass.

    | Lane | Current State | Primary Remaining Server-Blocked Item | Verification Packet |
    | --- | --- | --- | --- |
    | `cpp` | `baseline_complete` | no lane-local JDBC/.NET-class baseline gaps remain | `docs/development/server-verification/cpp.md` |
| `cli` | `tooling_partial` | tooling lane remains partial on TXN, META, TYPE, and RES in the lane-local mapping | `docs/development/server-verification/cli.md` |
| `dart` | `partial` | TXN: live failure-path validation remains open | `docs/development/server-verification/dart.md` |
| `dbeaver` | `partial_plugin` | UI plugin packaging and update-site installation proof remain open | `docs/development/server-verification/dbeaver.md` |
| `dotnet` | `baseline_complete` | no lane-local JDBC/.NET-class baseline gaps remain | `docs/development/server-verification/dotnet.md` |
| `elixir` | `partial` | EXEC: no standalone public portal-resume helper and deterministic stream/paging proof remains limited | `docs/development/server-verification/elixir.md` |
| `go` | `baseline_complete` | no lane-local JDBC/.NET-class baseline gaps remain | `docs/development/server-verification/go.md` |
| `hibernate` | `partial_contract_only` | current lane is still contract-first rather than fully validated runtime integration | `docs/development/server-verification/hibernate.md` |
| `jdbc` | `baseline_complete` | no lane-local JDBC/.NET-class baseline gaps remain | `docs/development/server-verification/jdbc.md` |
| `metabase` | `partial_adapter` | schema sync, field fingerprinting, and native-query validation remain server-blocked | `docs/development/server-verification/metabase.md` |
| `mojo` | `hybrid_native_gap` | architectural gap: replace the Python bridge with a native SBWP client / native Mojo transport | `docs/development/server-verification/mojo.md` |
| `node` | `baseline_complete` | no lane-local JDBC/.NET-class baseline gaps remain | `docs/development/server-verification/node.md` |
| `odbc` | `partial` | META remains partial because broader full-family metadata parity and richer catalog surfaces are still incomplete | `docs/development/server-verification/odbc.md` |
| `pascal` | `baseline_complete` | no lane-local JDBC/.NET-class baseline gaps remain | `docs/development/server-verification/pascal.md` |
| `php` | `baseline_complete` | no lane-local JDBC/.NET-class baseline gaps remain | `docs/development/server-verification/php.md` |
| `prisma` | `partial_contract_only` | current lane is still contract-first rather than fully validated runtime integration | `docs/development/server-verification/prisma.md` |
| `python` | `baseline_complete` | no lane-local JDBC/.NET-class baseline gaps remain | `docs/development/server-verification/python.md` |
| `r` | `partial` | CONN: connection/auth integration coverage remains environment-gated | `docs/development/server-verification/r.md` |
| `ruby` | `baseline_complete` | no lane-local JDBC/.NET-class baseline gaps remain | `docs/development/server-verification/ruby.md` |
| `rust` | `baseline_complete` | no lane-local JDBC/.NET-class baseline gaps remain | `docs/development/server-verification/rust.md` |
| `sqlalchemy` | `partial_adapter` | deep reflection, DDL compilation, and Alembic behavior remain server-blocked | `docs/development/server-verification/sqlalchemy.md` |
| `superset` | `partial_adapter` | EngineSpec behavior, SQL Lab validation, and deployment packaging remain server-blocked | `docs/development/server-verification/superset.md` |
| `swift` | `partial` | EXEC: live cancellation timing and portal suspend/resume coverage remains open | `docs/development/server-verification/swift.md` |
| `typeorm` | `partial_contract_only` | current lane is still contract-first rather than fully validated runtime integration | `docs/development/server-verification/typeorm.md` |
