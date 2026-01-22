# ScratchBird Rust Driver

Async Rust driver for ScratchBird using the native wire protocol.

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
