[Back to Drivers](Driver-Comparison.md) | [Back to Home](../Home.md)

# ODBC Driver Guide

**Status:** Implemented (SBWP v1.1 baseline)
**Last Updated:** 2026-02-02

---

## Overview

Native ScratchBird ODBC 3.8 driver using SBWP v1.1 on port 3092.

## Install

```bash
cmake -S . -B build
cmake --build build
```

## Quick Start

```text
Driver={ScratchBird ODBC Driver};Server=localhost;Port=3092;Database=mydb;UID=app_user;PWD=secret
```

## Documentation

- [ODBC connectivity guide](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/user-documentation/connectivity/odbc.md)
- [ODBC driver specification](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/specifications/drivers/ODBC_DRIVER_SPECIFICATION.md)

## Configuration

See [DSN and config standard](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/specifications/DRIVER_DSN_AND_CONFIG_STANDARD.md).

## Testing

See `docs/development/build-and-test.md` for ODBC build and test steps.

