# ODBC Connectivity

Connect to ScratchBird using the native ScratchBird ODBC 3.8 driver.

[Back to Connectivity Index](README.md) | [Back to Documentation Index](../README.md)

## Overview

The ODBC lane wraps the ScratchBird native protocol behind standard ODBC handle,
statement, metadata, and diagnostics entry points.

Use this guide when wiring the driver into unixODBC/iODBC, pyodbc,
`System.Data.Odbc`, Excel/Power BI, or another ODBC-capable client.

## Build And Register

Build the lane from the repo root:

```bash
cmake -S tracks/p3/drivers/odbc -B tracks/p3/drivers/odbc/build
cmake --build tracks/p3/drivers/odbc/build --config Release
```

Register the shared library in `odbcinst.ini`:

```ini
[ScratchBird]
Description = ScratchBird ODBC Driver
Driver = /path/to/libscratchbird_odbc.so
Setup = /path/to/libscratchbird_odbc.so
UsageCount = 1
```

## DSN Examples

Direct/native:

```ini
[ScratchBirdDirect]
Driver = ScratchBird
Server = 127.0.0.1
Port = 3092
Database = mydb
UID = user
PWD = pass
SSLMode = prefer
```

Manager-proxy:

```ini
[ScratchBirdManaged]
Driver = ScratchBird
Server = 127.0.0.1
Port = 3090
Database = mydb
UID = user
PWD = pass
FrontDoorMode = manager_proxy
ManagerAuthToken = token
```

## DSN-Less Connection Strings

Direct/native:

```
Driver={ScratchBird};Server=127.0.0.1;Port=3092;Database=mydb;UID=user;PWD=pass;SSLMode=prefer
```

Manager-proxy:

```
Driver={ScratchBird};Server=127.0.0.1;Port=3090;Database=mydb;UID=user;PWD=pass;FrontDoorMode=manager_proxy;ManagerAuthToken=token
```

## Supported Connection Keys

Core keys:

- `Driver`, `Server`/`Host`, `Port`, `Database`
- `UID`/`User`, `PWD`/`Password`
- `SSL`/`SSLMode`, `SSLCert`, `SSLKey`, `SSLRootCert`, `SSLPassword`
- `Timeout`, `QueryTimeout`, `ApplicationName`/`App`
- `Schema`/`CurrentSchema`, `ReadOnly`, `AutoCommit`, `Pooling`

Managed/auth-plugin keys:

- `FrontDoorMode`, `ManagerAuthToken`, `ManagerConnectionProfile`,
  `ManagerClientIntent`, `ManagerClientFlags`, `ManagerAuthFastPath`
- `ClientFlags`/`ConnectClientFlags`, `AuthMethodId`, `AuthMethodPayload`,
  `AuthPayloadJson`, `AuthPayloadB64`, `AuthProviderProfile`,
  `AuthRequiredMethods`, `AuthForbiddenMethods`,
  `AuthRequireChannelBinding`, `WorkloadIdentityToken`,
  `ProxyPrincipalAssertion`

## Programming Examples

### Python (`pyodbc`)

```python
import pyodbc

conn = pyodbc.connect(
    "Driver={ScratchBird};"
    "Server=127.0.0.1;"
    "Port=3092;"
    "Database=mydb;"
    "UID=user;"
    "PWD=pass;"
    "SSLMode=prefer"
)

cursor = conn.cursor()
cursor.execute("SELECT 1")
print(cursor.fetchone())
conn.close()
```

### C/C++

```c
#include <sql.h>
#include <sqlext.h>

SQLHENV env = SQL_NULL_HENV;
SQLHDBC dbc = SQL_NULL_HDBC;
SQLHSTMT stmt = SQL_NULL_HSTMT;

SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &env);
SQLSetEnvAttr(env, SQL_ATTR_ODBC_VERSION, (void*)SQL_OV_ODBC3, 0);
SQLAllocHandle(SQL_HANDLE_DBC, env, &dbc);

SQLDriverConnect(
    dbc,
    NULL,
    (SQLCHAR*)"Driver={ScratchBird};Server=127.0.0.1;Port=3092;Database=mydb;UID=user;PWD=pass;SSLMode=prefer",
    SQL_NTS,
    NULL,
    0,
    NULL,
    SQL_DRIVER_NOPROMPT
);

SQLAllocHandle(SQL_HANDLE_STMT, dbc, &stmt);
SQLExecDirect(stmt, (SQLCHAR*)"SELECT 1", SQL_NTS);

SQLFreeHandle(SQL_HANDLE_STMT, stmt);
SQLDisconnect(dbc);
SQLFreeHandle(SQL_HANDLE_DBC, dbc);
SQLFreeHandle(SQL_HANDLE_ENV, env);
```

## Diagnostics

Use standard ODBC diagnostics APIs:

- `SQLGetDiagRec`
- `SQLGetDiagField`

The lane maps ScratchBird/server failures into SQLSTATE-driven ODBC errors.

## See Also

- [ODBC getting started](../../getting-started/odbc.md)
- [ODBC API reference](../../api-reference/odbc.md)
- [JDBC connectivity](jdbc.md)
