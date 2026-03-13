# JDBC Connectivity

Connect to ScratchBird from Java applications using the native JDBC driver.

[Back to Connectivity Index](README.md) | [Back to Documentation Index](../README.md)

---

## Overview

ScratchBird ships a native JDBC driver (Type 4) that speaks the ScratchBird wire
protocol (SBWP v1.1) on port 3092.

---

## Build

```bash
cd tracks/p3/drivers/jdbc
./gradlew build
```

Jar output: `tracks/p3/drivers/jdbc/build/libs/scratchbird-jdbc.jar`

---

## Connection URL

```
jdbc:scratchbird://host[:port]/database
```

Manager-proxy example:

```
jdbc:scratchbird://host:3090/database?front_door_mode=manager_proxy&manager_auth_token=token
```

---

## SSL/TLS Options

Use standard JDBC properties:

```
sslmode=disable|allow|prefer|require|verify-ca|verify-full
sslrootcert=/path/to/ca.pem
sslcert=/path/to/client-keystore.p12
sslpassword=keystore_password
```

Compatibility and startup options commonly used with the current JDBC lane:

```
binaryTransfer=false
compression=zstd|none|off
client_flags=256
auth_method_payload=opaque-token
auth_required_methods=scratchbird.auth.scram_sha_256
auth_forbidden_methods=scratchbird.auth.password_compat
auth_require_channel_binding=true
workload_identity_token=jwt
proxy_principal_assertion=signed-assertion
```

---

## Examples

```java
String url = "jdbc:scratchbird://localhost:3092/mydb";
Connection conn = DriverManager.getConnection(url, "admin", "secret");
```

```java
Properties props = new Properties();
props.setProperty("user", "admin");
props.setProperty("password", "secret");
props.setProperty("sslmode", "require");
props.setProperty("sslrootcert", "/etc/ssl/certs/ca.pem");

Connection conn = DriverManager.getConnection(
    "jdbc:scratchbird://localhost:3092/mydb", props);
```

---

## Documentation

- [Getting started](../../getting-started/jdbc.md)
- [API reference](../../api-reference/jdbc.md)
- [DSN and config standard](../../specifications/DRIVER_DSN_AND_CONFIG_STANDARD.md)
- [JDBC driver specification](../../specifications/drivers/JDBC_DRIVER_SPECIFICATION.md)
