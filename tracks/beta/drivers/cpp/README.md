# ScratchBird C/C++ Client (`libscratchbird_client`)

Native C/C++ client library for ScratchBird SBWP v1.1.

## Lane Docs

- [Baseline Requirement Mapping (S0)](./BASELINE_REQUIREMENT_MAPPING.md)
- [Build Matrix](docs/BUILD_MATRIX.md)
- [Getting started](../../../../docs/getting-started/cpp.md)
- [API reference](../../../../docs/api-reference/cpp.md)

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Linux | Supported | CI build coverage. |
| Windows | Supported | CI build coverage. |
| macOS | Untested | Not currently covered in CI. |

## Build

```bash
cmake -S . -B build
cmake --build build --config Release
```

See `docs/BUILD_MATRIX.md` for toolchain prerequisites.

## Quick Start

```c
#include <scratchbird/client/scratchbird_client.h>

int main(void) {
    sb_error err = {0};
    sb_connection* conn =
        sb_connect("scratchbird://user:pass@127.0.0.1:3092/mydb", &err);
    if (!conn) {
        return 1;
    }

    sb_result* result = sb_query(conn, "SELECT 1", &err);
    if (result) {
        sb_result_free(result);
    }
    sb_disconnect(conn);
    return 0;
}
```

Direct and manager-proxy listener modes are supported. The lane remains
listener/IP-bound and does not implement driver-side IPC transport.

The public C++ surface now also includes:

- parsed `ConnectionConfig` mirroring listener-bound role/schema/app/TLS and
  compression settings
- `PreparedStatement` with typed parameter setters and execute helpers
- `ConnectionPool` and `ConnectionLease` RAII wrappers over the pooled C API
