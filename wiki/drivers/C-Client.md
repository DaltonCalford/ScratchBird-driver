[Back to Drivers](Driver-Comparison.md) | [Back to Home](../Home.md)

# C/C++ Client Driver Guide

**Status:** Initial Early Beta (`0.1.0`) (SBWP v1.1 baseline; C API type coverage expanding)
**Last Updated:** 2026-02-18

---

## Overview

Native C/C++ client library (libscratchbird_client) for SBWP v1.1.

## Install

```bash
cd tracks/beta/drivers/cpp
cmake -S . -B build
cmake --build build
```

## Quick Start

```c
#include <scratchbird/client/scratchbird_client.h>

int main(void) {
    sb_error err = {0};
    sb_connection* conn = sb_connect("scratchbird://user:pass@localhost:3092/mydb", &err);
    if (!conn) {
        return 1;
    }

    sb_result* result = sb_query(conn, "SELECT 1", &err);
    if (result) {
        sb_row row = {0};
        if (sb_fetch(result, &row, &err)) {
            int64_t value = 0;
            sb_get_int64(&row, 0, &value);
        }
        sb_result_free(result);
    }

    sb_disconnect(conn);
    return 0;
}
```

## Documentation

- [Client API specification](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/specifications/api/CLIENT_LIBRARY_API_SPECIFICATION.md)
- [Header reference](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/tracks/beta/drivers/cpp/include/scratchbird/client/scratchbird_client.h)

## Configuration

See [DSN and config standard](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/specifications/DRIVER_DSN_AND_CONFIG_STANDARD.md).

## Testing

See `docs/development/build-and-test.md` for C/C++ build and test steps.
