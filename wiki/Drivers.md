# Drivers

Complete installation and usage guide for each ScratchBird native SBWP driver.

Note: Package names and registries are still being finalized for first release.
If a package is not published yet, build the driver from this repository.

---

## C/C++ (libscratchbird_client) + ODBC

### Build

```bash
cd tracks/beta/drivers/cpp
cmake -S . -B build
cmake --build build
```

### Notes

- `tracks/beta/drivers/cpp` provides the C/C++ client library (SBWP v1.1).
- `tracks/alpha/drivers/odbc` provides the ODBC 3.8 driver (SBWP v1.1).

---

## Go

### Install

```bash
go get github.com/scratchbird/scratchbird-go
```

### Usage

```go
import (
    "database/sql"
    _ "github.com/scratchbird/scratchbird-go"
)

func main() {
    db, err := sql.Open("scratchbird", "scratchbird://user:pass@localhost:3092/mydb")
    if err != nil {
        panic(err)
    }
    defer db.Close()

    var one int
    if err := db.QueryRow("SELECT 1").Scan(&one); err != nil {
        panic(err)
    }
}
```

### Prepared Statements

```go
stmt, err := db.Prepare("SELECT ?::INTEGER")
row := stmt.QueryRow(42)
```

### Test Env

- `SCRATCHBIRD_GO_URL`

---

## Python

### Install

```bash
pip install scratchbird
```

### Usage

```python
import scratchbird

conn = scratchbird.connect("scratchbird://user:pass@localhost:3092/mydb")
cur = conn.cursor()
cur.execute("SELECT 1 AS one")
print(cur.fetchone())
conn.close()
```

### Parameters

Positional or named parameters with `:name` placeholders:

```python
cur.execute("SELECT :v::INTEGER", {"v": 42})
```

### Test Env

- `SCRATCHBIRD_TEST_DSN`

---

## Node.js / TypeScript

### Install

```bash
npm install scratchbird
```

### Usage

```ts
import { Client } from "scratchbird";

const client = new Client({
  host: "localhost",
  port: 3092,
  user: "user",
  password: "pass",
  database: "db",
});

await client.connect();
const res = await client.query("SELECT 1 AS one");
console.log(res.rows);
await client.end();
```

### Test Env

- `SCRATCHBIRD_NODE_URL`

---

## Ruby

### Install

```bash
gem build scratchbird.gemspec
gem install scratchbird-0.1.0.gem
```

### Usage

```ruby
require "scratchbird"

conn = Scratchbird.connect("scratchbird://user:pass@localhost:3092/mydb")
result = conn.query("SELECT 1 AS one")
puts result.first[0]
conn.close
```

### Test Env

- `SCRATCHBIRD_RUBY_URL`

---

## Rust

### Install

Add to `Cargo.toml`:

```toml
scratchbird = "0.1.0"
```

### Usage

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

### Test Env

- `SCRATCHBIRD_RUST_URL`

---

## PHP

### Install

```bash
composer install
```

### Usage

```php
use ScratchBird\PDO\ScratchBirdPDO;

$pdo = new ScratchBirdPDO("scratchbird://user:pass@localhost:3092/mydb");
$stmt = $pdo->query("SELECT 1");
$row = $stmt->fetch();
```

### Test Env

- `SCRATCHBIRD_PHP_URL`

---

## R

### Install

```r
install.packages("scratchbird", repos = NULL, type = "source")
```

### Usage

```r
library(DBI)
library(scratchbird)

con <- dbConnect(Scratchbird(), "scratchbird://user:pass@localhost:3092/mydb")
res <- dbGetQuery(con, "SELECT 1")
dbDisconnect(con)
```

### Test Env

- `SCRATCHBIRD_R_URL`

---

## Pascal / Delphi

### Install

Add `pascal/src` to your project search path.

### Usage

```pascal
uses
  ScratchBird.Client;

var
  Client: TScratchBirdClient;
begin
  Client := TScratchBirdClient.Create;
  try
    Client.Connect('scratchbird://user:pass@localhost:3092/mydb');
    Client.ExecSQL('SELECT 1');
  finally
    Client.Free;
  end;
end;
```

### Framework Adapters

- FireDAC: `ScratchBird.FireDAC`
- IBX: `ScratchBird.IBX`
- Zeos: `ScratchBird.Zeos`
- SQLdb: `ScratchBird.SQLdb`

### Test Env

- `SCRATCHBIRD_PASCAL_URL`

---

## .NET

### Install

```bash
dotnet build src/ScratchBird.Data/ScratchBird.Data.csproj
```

### Usage

```csharp
using ScratchBird.Data;

var conn = new ScratchBirdConnection("scratchbird://user:pass@localhost:3092/mydb");
conn.Open();

using var cmd = conn.CreateCommand();
cmd.CommandText = "SELECT 1";
var result = cmd.ExecuteScalar();

conn.Close();
```

### Test Env

- `SCRATCHBIRD_DOTNET_URL`

---

## JDBC (Java)

### Build

```bash
cd jdbc
./gradlew build
```

### Usage

```java
import java.sql.Connection;
import java.sql.DriverManager;

Connection conn = DriverManager.getConnection(
    "jdbc:scratchbird://localhost:3092/mydb",
    "user",
    "password"
);
```

### Connection Properties

```java
Properties props = new Properties();
props.setProperty("user", "myuser");
props.setProperty("password", "mypass");
props.setProperty("sslmode", "require");
```

### Test Env

- `SCRATCHBIRD_JDBC_URL`
- `SCRATCHBIRD_JDBC_USER`
- `SCRATCHBIRD_JDBC_PASSWORD`

---

## Elixir (Ecto) - Preview

Spec:
https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/specifications/DRIVER_ELIXIR_ECTO_ADAPTER.md

Notes:
- SBWP v1.1 client + `ecto_sql`/`db_connection` adapter.
- Binary-only transfer with server-side prepare/bind.

---

## Swift Async/Await - Preview

Spec:
https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/specifications/DRIVER_SWIFT_ASYNC_ADAPTER.md

Notes:
- Swift Concurrency API with async/await.
- TCP transport in place; TLS wiring pending.

---

## Dart - Preview

Spec:
https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/specifications/DRIVER_DART_DATABASE_API.md

Notes:
- Flutter-ready Dart driver with async/await.
- Binary-only SBWP v1.1 protocol implementation.

---

## Mojo - Preview

Spec:
https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/specifications/DRIVER_MOJO_NATIVE_API.md

Notes:
- SBWP v1.1 API surface available via Mojo-Python interop.
- Python bridge can be swapped for native Mojo TCP/TLS later.

---

## Application Integrations

For Metabase and Superset integration, see:

- [Metabase Driver](Metabase-Driver)
- [Superset Driver](Superset-Driver)

---

**Last Updated:** 2026-02-02
