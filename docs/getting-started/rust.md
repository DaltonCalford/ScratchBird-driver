# Rust Driver

<!-- lane-status:start -->
## Current Status

- Lane kind: `driver`
- Current state: `baseline_complete`
- Best-in-class benchmark: `tokio-postgres`
- Authoritative lane spec: `docs/specifications/drivers/language/rust/SPECIFICATION.md`
- Shared release evidence templates: `docs/development/release-evidence/README.md`
- Later verification packet: `docs/development/server-verification/rust.md`
- Remaining gap summary: No lane-local JDBC/.NET-class baseline gaps remain. Remaining work is live proof collection and release evidence staging.
<!-- lane-status:end -->

## Install

Add the crate as a dependency or use a local path during repo development:

```toml
[dependencies]
scratchbird = { path = "../tracks/p3/drivers/rust" }
```

## Quick Start

```rust
use scratchbird::{Client, Config};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let mut client = Client::new(Config::from_dsn(
        "scratchbird://user:pass@localhost:3092/mydb",
    )?);
    client.connect().await?;
    let result = client.query("SELECT 1").await?;
    println!("{:?}", result.rows[0][0]);
    client.close().await;
    Ok(())
}
```

## Connection Strings

Direct/native:

```
scratchbird://user:password@host:3092/database?sslmode=prefer
```

Manager-proxy:

```
scratchbird://user:password@host:3090/database?front_door_mode=manager_proxy&manager_auth_token=token
```

Current lane behavior:

- Direct DSNs accept the standard `sslmode` values, including `disable`.
- Compatibility startup keys include `binary_transfer=false` and
  `compression=zstd|none|off`.
- Manager-proxy and auth-plugin startup keys are supported.

## Tests

Integration tests are gated by:

- `SCRATCHBIRD_RUST_URL`
