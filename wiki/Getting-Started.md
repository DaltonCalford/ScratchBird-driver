# Getting Started

All drivers connect to ScratchBird using SBWP v1.1 over TLS 1.3. Binary transfer mode is required.

## Connection Strings

### URI Format

```
scratchbird://user:password@host:3092/database?sslmode=require
```

### Key-Value Format

```
host=localhost port=3092 dbname=mydb user=myuser password=mypass sslmode=require
```

## Configuration Options

### Required

| Key | Description |
|-----|-------------|
| host | Server hostname or IP |
| port | Server port (default: 3092) |
| database / dbname | Database name |
| user | Username |

### Optional

| Key | Description | Default |
|-----|-------------|---------|
| password | User password | - |
| role | Session role | - |
| sslmode | TLS mode (require/verify-ca/verify-full) | require |
| sslrootcert | CA certificate path | - |
| sslcert | Client certificate path | - |
| sslkey | Client key path | - |
| sslpassword | Client key passphrase | - |
| connect_timeout | Connection timeout (seconds) | 30 |
| socket_timeout | Socket timeout (seconds) | 0 |
| application_name | Application identifier | - |
| compression | Compression (off only; zstd disabled) | off |
| fetch_size | Rows per portal fetch (paging) | 0 (all) |

### Key Aliases

These aliases are accepted by all drivers:

- `database` / `dbname`
- `user` / `username`
- `application_name` / `applicationName`
- `connect_timeout` / `connectTimeout`
- `socket_timeout` / `socketTimeout`
- `fetch_size` / `fetchSize`

### Binary Transfer Mode

All drivers enforce binary-only transfer. Setting `binary_transfer=false` is rejected with SQLSTATE 0A000 (feature not supported).

### Compression

zstd compression is currently disabled pending server-side implementation. Setting `compression=zstd` will be rejected.

## TLS Requirements

- TLS 1.3 is mandatory
- `sslmode=disable` is rejected by all drivers
- Minimum mode is `sslmode=require`

## Quick Examples

### Go

```go
import (
    "database/sql"
    _ "github.com/scratchbird/scratchbird-go"
)

db, err := sql.Open("scratchbird", "scratchbird://user:pass@localhost:3092/mydb")
```

### Python

```python
import scratchbird

conn = scratchbird.connect("scratchbird://user:pass@localhost:3092/mydb")
cur = conn.cursor()
cur.execute("SELECT 1")
```

### Node.js

```ts
import { Client } from "scratchbird";

const client = new Client({ host: "localhost", port: 3092, user: "user", password: "pass", database: "db" });
await client.connect();
const res = await client.query("SELECT 1");
```

### Rust

```rust
use scratchbird::{Client, Config};

let mut client = Client::new(Config::from_dsn("scratchbird://user:pass@localhost:3092/mydb")?);
client.connect().await?;
```

### Java (JDBC)

```java
Connection conn = DriverManager.getConnection(
    "jdbc:scratchbird://localhost:3092/mydb", "user", "password"
);
```

See the [Drivers](Drivers) page for complete examples for all languages.

## CLI Tools

Native and emulated protocol CLI tools are documented here:

- [CLI Tools](cli-tools/README)
