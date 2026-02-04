# JDBC Driver

## Build

```bash
cd tracks/alpha/drivers/jdbc
./gradlew build
```

## Quick Start

```java
import java.sql.Connection;
import java.sql.DriverManager;

Connection conn = DriverManager.getConnection(
    "jdbc:scratchbird://localhost:3092/mydb",
    "user",
    "password"
);
```

## Connection Strings

JDBC URL:

```
jdbc:scratchbird://host:3092/database?sslmode=require
```

Property-based:

```
Properties props = new Properties();
props.setProperty("user", "myuser");
props.setProperty("password", "mypass");
props.setProperty("sslmode", "require");
```

See [DSN and config standard](../specifications/DRIVER_DSN_AND_CONFIG_STANDARD.md).

## TLS

TLS 1.3 is required. `sslmode=disable` is rejected.

## Tests

Integration tests are gated by:

- `SCRATCHBIRD_JDBC_URL`
- `SCRATCHBIRD_JDBC_USER`
- `SCRATCHBIRD_JDBC_PASSWORD`
