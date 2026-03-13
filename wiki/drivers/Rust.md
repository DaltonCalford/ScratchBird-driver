[Back to Drivers](Driver-Comparison.md) | [Back to Home](../Home.md)

# Rust Driver Guide

**Status:** Initial Early Beta (`0.1.0`) (SBWP v1.1 baseline)
**Last Updated:** 2026-02-18

---

## Overview

Async Rust driver for ScratchBird using SBWP v1.1.

## Install

```toml
# Cargo.toml
scratchbird = "0.1.0"
```

## Quick Start

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

## Documentation

- [Getting started](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/getting-started/rust.md)
- [API reference](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/api-reference/rust.md)
- [Driver README](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/tracks/p3/drivers/rust/README.md)

## Configuration

See [DSN and config standard](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/specifications/DRIVER_DSN_AND_CONFIG_STANDARD.md).

## Testing

Integration tests use `SCRATCHBIRD_RUST_URL`.

