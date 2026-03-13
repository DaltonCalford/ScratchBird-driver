# C/C++ Client

## Build

From the repo root:

```bash
cmake -S tracks/p3/drivers/cpp -B tracks/p3/drivers/cpp/build
cmake --build tracks/p3/drivers/cpp/build --config Release
```

The public headers live under `tracks/p3/drivers/cpp/include/`.

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

    sb_result* result = sb_query(conn, "SELECT 1 AS one", &err);
    if (result) {
        sb_result_free(result);
    }

    sb_disconnect(conn);
    return 0;
}
```

## Connection Strings

Direct/native:

```
scratchbird://user:password@127.0.0.1:3092/database?sslmode=prefer
```

Manager-proxy:

```
scratchbird://user:password@127.0.0.1:3090/database?front_door_mode=manager_proxy&manager_auth_token=token
```

Current C/C++ lane notes:

- Transport is intentionally IP-only. Use listener/network endpoints, not IPC.
- Direct and manager-proxy ingress are supported.
- Compatibility startup flags include `binary_transfer=false` and
  `compression=zstd|none|off`.
- Auth-plugin handshake inputs include `client_flags|connect_client_flags`,
  `auth_method_payload`, `auth_required_methods`, `auth_forbidden_methods`,
  `auth_require_channel_binding`, `workload_identity_token`, and
  `proxy_principal_assertion`.

## Higher-Level Surfaces

- C++ wrapper classes are available under `scratchbird/client/connection.h`.
- Parsed DSN-to-`ConnectionConfig` helpers are available through
  `parseConnectionConfig(...)`.
- Typed C++ prepared statements are available through `Connection::prepare(...)`
  and `PreparedStatement`.
- Pooling helpers live in `scratchbird/client/pool.h`.
- Query pipelining helpers live in `scratchbird/client/pipeline.h`.
- Enterprise diagnostics, telemetry, and notification APIs are available in the
  C API and mirrored by the lane tests.

## Tests

The lane test suite is built with CMake. After configuring the build:

```bash
ctest --test-dir tracks/p3/drivers/cpp/build --output-on-failure
```
