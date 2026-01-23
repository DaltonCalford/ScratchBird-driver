# Rust Driver

## Install

Add to Cargo.toml:

```toml
scratchbird = "0.1.0"
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

URI:

```
scratchbird://user:password@host:3092/database?sslmode=require
```

Key-value:

```
host=localhost port=3092 dbname=mydb user=myuser password=mypass
```

See [DSN and config standard](../specifications/DRIVER_DSN_AND_CONFIG_STANDARD.md).

## TLS

TLS 1.3 is required. `sslmode=disable` is rejected.

## Tests

Integration tests are gated by:

- `SCRATCHBIRD_RUST_URL`
