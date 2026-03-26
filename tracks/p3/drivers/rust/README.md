# ScratchBird Rust Driver

Async Rust driver for ScratchBird using the native wire protocol.

## Documentation

- [Getting started](../../../../docs/getting-started/rust.md)
- [API reference](../../../../docs/api-reference/rust.md)
- [Baseline requirement mapping](BASELINE_REQUIREMENT_MAPPING.md)

## MGA Recovery Contract

This lane follows ScratchBird's MGA/state-based engine recovery model.

- reconnect or reopen only repairs transport and session state
- reconnect never resurrects abandoned in-flight transactions or replay lost statements
- transaction recovery in the lane means reset, rollback, reopen, or retry against engine truth
- result resume is valid only for explicit suspended protocol states
- `Client::prepare_transaction(...)`, `commit_prepared(...)`, and
  `rollback_prepared(...)` expose prepared/limbo control SQL explicitly in
  lane source
- `supports_dormant_reattach()` is explicit and `detach_to_dormant(...)` /
  `reattach_dormant(...)` fail closed with `0A000` instead of implying that
  reconnect can recover dormant work
- `TxnBeginOptions` exposes the canonical MGA begin flags for
  `isolation_level`, `access_mode`, `deferrable`, `wait`, `timeout_ms`,
  `autocommit_mode`, `conflict_action`, and `read_committed_mode`
- current isolation alias mapping is explicit in lane source:
  `READ COMMITTED` => canonical `READ COMMITTED`,
  `REPEATABLE READ` => canonical `SNAPSHOT`,
  `SERIALIZABLE` => canonical `SNAPSHOT TABLE STABILITY`
- the public `READ_COMMITTED_MODE_*` constants plus
  `canonical_read_committed_mode_label(...)` make the canonical
  `READ COMMITTED` sub-modes explicit in lane source; `read_committed_mode`
  now exposes `READ COMMITTED READ CONSISTENCY` directly
- `retry_scope_for_sqlstate(...)` makes the retry boundary explicit:
  `40001`/`40P01` => fresh statement only, `08xxx` => reconnect or reopen
  only, everything else => no automatic replay
- native `READY` / `TXN_STATUS` frames now own transaction activity in lane
  source, so a fresh native MGA boundary can remain active while `txn_id == 0`
- compatible default `READ COMMITTED` `begin(...)` calls now adopt that
  already-active fresh native boundary, while unsupported non-default
  fresh-boundary begin requests fail closed with `0A000`
- native autocommit transitions stay local to the wrapper instead of sending
  `SET_OPTION autocommit` against a server-owned fresh boundary

See `../../../../docs/audit/MGA_RECONNECT_AND_TRANSACTION_RECOVERY_AUDIT.md`.

## Build/Test (Windows/Linux)

See `docs/BUILD_MATRIX.md`.

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Linux | Supported | CI build/test coverage. |
| Windows | Supported | CI build/test coverage. |
| macOS | Untested | Not currently covered in CI. |

## Usage

```rust
use scratchbird::{Client, Config};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let mut client = Client::new(Config::from_dsn(
        "scratchbird://user:pass@localhost:3092/mydb"
    )?);
    client.connect().await?;
    let result = client.query("SELECT 1").await?;
    println!("{:?}", result.rows[0][0]);
    client.close().await;
    Ok(())
}
```

## Connection strings

URI:

```
scratchbird://user:password@host:3092/database?sslmode=require
```

Key-value:

```
host=localhost port=3092 dbname=mydb user=myuser password=mypass
```
