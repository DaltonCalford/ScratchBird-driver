# JDBC Driver

## Build

```bash
cd tracks/alpha/drivers/jdbc
./gradlew build
```

Requires JDK 17. The Gradle wrapper is pinned to 8.5+ for JDK 21 compatibility.

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
jdbc:scratchbird://host:3092/database?sslmode=prefer
```

Manager-proxy:

```
jdbc:scratchbird://host:3090/database?front_door_mode=manager_proxy&manager_auth_token=token
```

Current lane behavior:

- Direct DSNs accept the standard `sslmode` values, including `disable`.
- Compatibility startup keys include `binaryTransfer=false` and
  `compression=zstd|none|off`.
- Manager-proxy and auth-plugin startup keys are supported, including
  `client_flags`, `auth_method_payload`, `auth_required_methods`,
  `auth_forbidden_methods`, `auth_require_channel_binding`,
  `workload_identity_token`, and `proxy_principal_assertion`.

## Tests

Integration tests are gated by:

- `SCRATCHBIRD_JDBC_URL`
- `SCRATCHBIRD_JDBC_USER`
- `SCRATCHBIRD_JDBC_PASSWORD`
