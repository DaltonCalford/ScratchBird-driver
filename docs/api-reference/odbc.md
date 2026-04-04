# ODBC Driver API Reference

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

## Driver Model

The ScratchBird ODBC lane implements an ODBC 3.8 driver surface over the
ScratchBird native protocol.

Primary exported entry points live in:

- `scratchbird/odbc/odbc_driver.h`

## Connection Lifecycle

- `SQLAllocHandle`
- `SQLDriverConnect` / `SQLDriverConnectW`
- `SQLDisconnect`
- `SQLSetConnectAttr`
- `SQLGetInfo` / `SQLGetInfoW`
- `SQLGetFunctions`

## Statement Execution

- `SQLPrepare` / `SQLPrepareW`
- `SQLExecute`
- `SQLExecDirect` / `SQLExecDirectW`
- `SQLBindParameter`
- `SQLBindCol`
- `SQLDescribeCol` / `SQLDescribeColW`
- `SQLFetch`, `SQLFetchScroll`
- `SQLMoreResults`

## Metadata Surfaces

- `SQLTables` / `SQLTablesW`
- `SQLColumns` / `SQLColumnsW`
- `SQLPrimaryKeys` / `SQLPrimaryKeysW`
- `SQLForeignKeys` / `SQLForeignKeysW`
- `SQLStatistics` / `SQLStatisticsW`
- `SQLSpecialColumns` / `SQLSpecialColumnsW`
- `SQLProcedures` / `SQLProceduresW`
- `SQLProcedureColumns` / `SQLProcedureColumnsW`
- `SQLGetTypeInfo`

## Transactions

- `SQLEndTran`
- `SQLSetConnectAttr(SQL_ATTR_AUTOCOMMIT, ...)`

## Connection String Keys

The current lane maps ODBC keys onto ScratchBird connection settings, including:

- Network/session keys:
  `Server`, `Host`, `Port`, `Database`, `UID`, `PWD`, `SSLMode`,
  `Timeout`, `QueryTimeout`, `ApplicationName`, `Schema`
- Managed ingress keys:
  `FrontDoorMode`, `ManagerAuthToken`, `ManagerConnectionProfile`,
  `ManagerClientIntent`, `ManagerClientFlags`, `ManagerAuthFastPath`
- Auth-plugin handshake keys:
  `ClientFlags`, `ConnectClientFlags`, `AuthMethodId`, `AuthMethodPayload`,
  `AuthPayloadJson`, `AuthPayloadB64`, `AuthProviderProfile`,
  `AuthRequiredMethods`, `AuthForbiddenMethods`,
  `AuthRequireChannelBinding`, `WorkloadIdentityToken`,
  `ProxyPrincipalAssertion`

## Diagnostics

The lane uses standard ODBC diagnostics:

- `SQLGetDiagRec`
- `SQLGetDiagField`

Server and protocol failures are normalized into SQLSTATE-driven ODBC errors.

## Related Guides

- [ODBC getting started](../getting-started/odbc.md)
- [ODBC connectivity guide](../user-documentation/connectivity/odbc.md)
- [ODBC baseline mapping](../../tracks/p3/drivers/odbc/BASELINE_REQUIREMENT_MAPPING.md)
