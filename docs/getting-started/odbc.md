# ODBC Driver

<!-- lane-status:start -->
## Current Status

- Lane kind: `driver`
- Current state: `partial`
- Best-in-class benchmark: `Microsoft ODBC Driver for SQL Server`
- Authoritative lane spec: `docs/specifications/drivers/ODBC_DRIVER_SPECIFICATION.md`
- Shared release evidence templates: `docs/development/release-evidence/README.md`
- Later verification packet: `docs/development/server-verification/odbc.md`
- Remaining gap summary: META remains partial because broader full-family metadata parity and richer catalog surfaces are still incomplete.
<!-- lane-status:end -->

## Build

From the repo root:

```bash
cmake -S tracks/p3/drivers/odbc -B tracks/p3/drivers/odbc/build
cmake --build tracks/p3/drivers/odbc/build --config Release
```

See `tracks/p3/drivers/odbc/docs/BUILD_MATRIX.md` for ODBC manager and
OpenSSL prerequisites.

## Register The Driver

On unixODBC/iODBC, register the built shared library in `odbcinst.ini`:

```ini
[ScratchBird]
Description = ScratchBird ODBC Driver
Driver = /path/to/libscratchbird_odbc.so
Setup = /path/to/libscratchbird_odbc.so
UsageCount = 1
```

## Quick Start

DSN-less example:

```ini
Driver={ScratchBird};
Server=127.0.0.1;
Port=3092;
Database=mydb;
UID=user;
PWD=pass;
SSLMode=prefer;
```

Manager-proxy example:

```ini
Driver={ScratchBird};
Server=127.0.0.1;
Port=3090;
Database=mydb;
UID=user;
PWD=pass;
FrontDoorMode=manager_proxy;
ManagerAuthToken=token;
```

## Supported Connection Keys

Common ODBC keys include:

- `Driver`, `Server`/`Host`, `Port`, `Database`, `UID`/`User`, `PWD`/`Password`
- `SSL`/`SSLMode`, `SSLCert`, `SSLKey`, `SSLRootCert`, `SSLPassword`
- `Timeout`, `QueryTimeout`, `ApplicationName`/`App`, `Schema`/`CurrentSchema`
- `FrontDoorMode`, `ManagerAuthToken`, `ManagerConnectionProfile`,
  `ManagerClientIntent`, `ManagerClientFlags`, `ManagerAuthFastPath`
- `ClientFlags`/`ConnectClientFlags`, `AuthMethodId`, `AuthMethodPayload`,
  `AuthPayloadJson`, `AuthPayloadB64`, `AuthProviderProfile`,
  `AuthRequiredMethods`, `AuthForbiddenMethods`,
  `AuthRequireChannelBinding`, `WorkloadIdentityToken`,
  `ProxyPrincipalAssertion`

## Programming Examples

- [ODBC connectivity guide](../user-documentation/connectivity/odbc.md)
- [ODBC API reference](../api-reference/odbc.md)

## Tests

After configuring the build:

```bash
ctest --test-dir tracks/p3/drivers/odbc/build --output-on-failure
```
