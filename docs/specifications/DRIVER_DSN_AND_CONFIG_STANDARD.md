# Driver DSN and Config Standard

Status: Draft
Last Updated: 2026-01-09

## Purpose

Define a single, canonical set of connection parameters for all native
ScratchBird drivers. Each driver may expose language-specific config objects,
but must normalize to the same canonical keys and semantics.

## Supported DSN Formats

### URI

scratchbird://user:password@host:3092/database?sslmode=require&application_name=app

### Key-Value

host=localhost port=3092 dbname=mydb user=myuser password=mypass sslmode=require

## Canonical Keys

Required:
- host
- port (default 3092)
- database (or dbname)
- user

Optional:
- password
- sslmode (disable|allow|prefer|require|verify-ca|verify-full)
- sslrootcert
- sslcert
- sslkey
- sslpassword
- connect_timeout (seconds)
- socket_timeout (seconds)
- application_name
- search_path (or currentSchema)
- role
- binary_transfer (must be true)
- compression (off|zstd)
- fetch_size (rows per page; 0 = all rows)

## Key Aliases (Must Accept)

- database, dbname
- user, username
- application_name, applicationName
- search_path, searchPath, currentSchema
- sslmode, ssl
- connect_timeout, connectTimeout
- socket_timeout, socketTimeout
- binary_transfer, binarytransfer
- fetch_size, fetchsize, default_fetch_size

## Binary-Only Requirement

All drivers must operate in binary transfer mode. If a driver receives
binary_transfer=false it must reject the connection with NotSupported.

## Precedence Rules

1. Explicit config fields set in code
2. DSN query parameters or key-value pairs
3. Driver defaults

## Security Rules

- Never log passwords or raw credentials.
- If sslmode=require or stronger, drivers must refuse plaintext.

## SQLSTATE Codes (Config Errors)

- 08001: cannot connect (invalid host/port)
- 28000: invalid authorization (missing user/password)
- 0A000: unsupported configuration option
- 22023: invalid parameter value (malformed timeout/port)

## Per-Language Config Mapping

### Go

- DSN keys: host, port, database/dbname, user/username, password/pwd,
  sslmode, sslrootcert, sslcert, sslkey, connect_timeout, socket_timeout,
  application_name, binary_transfer, compression, fetch_size.
- Config fields: Host, Port, Database, User, Password, SSLMode,
  SSLRootCert, SSLCert, SSLKey, ConnectTimeout, SocketTimeout,
  Application, BinaryTransfer, Compression, FetchSize.

### Node.js/TypeScript

- DSN keys: host, port, database/dbname, user, password, sslmode,
  sslrootcert, sslcert, sslkey, connect_timeout, socket_timeout,
  application_name, binary_transfer, compression.
- Config fields: host, port, database, user, password, sslmode,
  sslrootcert, sslcert, sslkey, connectTimeoutMs, socketTimeoutMs,
  applicationName, binaryTransfer, compression.

### Python

- DSN keys: host, port, database/dbname, user, password, sslmode/ssl,
  connect_timeout, socket_timeout, application_name, search_path,
  binary_transfer, compression, sslrootcert, sslcert, sslkey.
- Config fields: host, port, database, user, password, sslmode,
  connect_timeout, socket_timeout, application_name, search_path,
  binary_transfer, compression, extra.sslrootcert/sslcert/sslkey.

### Ruby

- DSN keys: host, port, database/dbname, user/username, password/pwd,
  sslmode, sslrootcert, sslcert, sslkey, connect_timeout, socket_timeout,
  application_name, binary_transfer, compression.
- Config fields: host, port, database, user, password, sslmode,
  sslrootcert, sslcert, sslkey, connect_timeout_ms, socket_timeout_ms,
  application_name, binary_transfer, compression.

### Rust

- DSN keys: host, port, database/dbname, user/username, password/pwd,
  sslmode, sslrootcert, sslcert, sslkey, connect_timeout, socket_timeout,
  application_name, binary_transfer, compression, fetch_size.
- Config fields: host, port, database, user, password, sslmode,
  sslrootcert, sslcert, sslkey, connect_timeout_ms, socket_timeout_ms,
  application_name, binary_transfer, compression, fetch_size.

### PHP

- DSN keys: host, port, database/dbname, user/username, password/pwd,
  sslmode, sslrootcert, sslcert, sslkey, connect_timeout, socket_timeout,
  application_name, binary_transfer, compression, fetch_size.
- Config fields: host, port, database, user, password, sslMode,
  sslRootCert, sslCert, sslKey, connectTimeoutMs, socketTimeoutMs,
  applicationName, binaryTransfer, compression, fetchSize.

### R

- DSN keys: host, port, database/dbname, user/username, password/pwd,
  sslmode, sslrootcert, sslcert, sslkey, connect_timeout, socket_timeout,
  application_name, binary_transfer, compression, fetch_size.
- Config fields: host, port, database, user, password, sslmode,
  sslrootcert, sslcert, sslkey, connect_timeout_ms, socket_timeout_ms,
  application_name, binary_transfer, compression, fetch_size.

### Pascal/Delphi

- DSN keys: host, port, database/dbname, user/username, password/pwd,
  sslmode, sslrootcert, sslcert, sslkey, connect_timeout, socket_timeout,
  application_name, binary_transfer, compression, fetch_size.
- Config fields: Host, Port, Database, UserName, Password, SSLMode,
  SSLRootCert, SSLCert, SSLKey, ConnectTimeoutMs, SocketTimeoutMs,
  ApplicationName, BinaryTransfer, Compression, FetchSize.

### .NET

- Connection string keys: Host, Port, Database, Username, Password,
  SSLMode, Timeout, CommandTimeout, Pooling, MinPoolSize, MaxPoolSize,
  ConnectionLifetime, Enlist, FetchSize.
- Required alias support: user -> Username, database/dbname -> Database.
- SSL cert key support is required even if not yet implemented.

### JDBC

- Properties keys: host, port, database/dbname, user, password,
  ssl/sslmode, sslcert, sslkey, sslrootcert, sslpassword,
  connecttimeout, sockettimeout, logintimeout, tcpkeepalive,
  currentSchema/searchPath, applicationName, readOnly, autocommit,
  defaultRowFetchSize (or fetch_size), prepareThreshold, binaryTransfer,
  compression,
  rewriteBatchedInserts.

### ODBC (Connection String Mapping)

ODBC connection strings must map to the canonical keys above:
- `Server`/`Host` -> host
- `Port` -> port
- `Database`/`DB` -> database
- `UID`/`User` -> user
- `PWD`/`Password` -> password
- `SSL`/`SSLMode` -> sslmode
- `SSLCert` -> sslcert
- `SSLKey` -> sslkey
- `SSLRootCert` -> sslrootcert
- `SSLPassword` -> sslpassword
- `ApplicationName`/`App` -> application_name
- `Schema`/`CurrentSchema` -> search_path
- `Role` -> role
- `BinaryTransfer` -> binary_transfer (must be true)
- `Compression` -> compression (off|zstd)
- `FetchSize`/`DefaultRowFetchSize` -> fetch_size
