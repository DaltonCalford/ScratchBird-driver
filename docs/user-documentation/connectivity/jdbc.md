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
cd tracks/alpha/drivers/jdbc
./gradlew build
```

Jar output: `tracks/alpha/drivers/jdbc/build/libs/scratchbird-jdbc.jar`

---

## Connection URL

```
jdbc:scratchbird://host[:port]/database
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

