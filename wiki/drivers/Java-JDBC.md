[Back to Drivers](Driver-Comparison.md) | [Back to Home](../Home.md)

# Java/JDBC Driver Guide

**Status:** Initial Early Beta (`0.1.0`) (SBWP v1.1 baseline)
**Last Updated:** 2026-02-18

---

## Overview

ScratchBird JDBC driver using SBWP v1.1.

## Install

```bash
cd tracks/p3/drivers/jdbc
./gradlew build
```

Requires JDK 17. The Gradle wrapper is pinned to 8.5+ for JDK 21 compatibility.
If you see `Unsupported class file major version 65`, ensure Gradle is 8.5+
or run with JDK 17. If Gradle reports missing toolchains, install JDK 17
and set `JAVA_HOME`.

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

## Documentation

- [Getting started](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/getting-started/jdbc.md)
- [API reference](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/api-reference/jdbc.md)
- [Driver README](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/tracks/p3/drivers/jdbc/README.md)

## Configuration

See [DSN and config standard](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/specifications/DRIVER_DSN_AND_CONFIG_STANDARD.md).

## Testing

Integration tests use `SCRATCHBIRD_JDBC_URL`, `SCRATCHBIRD_JDBC_USER`, and `SCRATCHBIRD_JDBC_PASSWORD`.
