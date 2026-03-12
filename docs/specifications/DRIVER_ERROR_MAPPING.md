# Driver Error Mapping

Status: Draft
Last Updated: 2026-01-09

## Purpose

Define a consistent error model across drivers, including SQLSTATE
classification and retriable vs fatal errors.

The machine-readable required SQLSTATE registry lives in
`docs/fixtures/sqlstate_required_set.json` and is the authoritative input for
cross-driver closure tooling.

## Binary-Only Requirement

SBWP error payloads are binary. Drivers must parse structured error fields
(message, sqlstate, detail, hint) from the binary protocol and must not
fall back to plain-text parsing.

## Required Error Fields

Drivers must surface:
- message
- sqlstate (when provided)
- server error code (when provided)
- retriable flag (driver-determined)

## SQLSTATE Codes (Required Set)

| SQLSTATE | Meaning | Class | Retriable |
| --- | --- | --- | --- |
| 01000 | warning | 01 | no |
| 02000 | no data | 02 | no |
| 08001 | cannot connect | 08 | yes |
| 08003 | connection does not exist | 08 | yes |
| 08004 | server rejected connection | 08 | no |
| 08006 | connection failure | 08 | yes |
| 08P01 | protocol violation | 08 | no |
| 0A000 | feature not supported | 0A | no |
| 22001 | string data right truncation | 22 | no |
| 22003 | numeric value out of range | 22 | no |
| 22007 | invalid datetime format | 22 | no |
| 22012 | division by zero | 22 | no |
| 22023 | invalid parameter value | 22 | no |
| 22P02 | invalid text representation | 22 | no |
| 22P03 | invalid binary representation | 22 | no |
| 23000 | integrity constraint violation | 23 | no |
| 23502 | not null violation | 23 | no |
| 23503 | foreign key violation | 23 | no |
| 23505 | unique violation | 23 | no |
| 23514 | check violation | 23 | no |
| 28000 | invalid authorization | 28 | no |
| 28P01 | invalid password | 28 | no |
| 40001 | serialization failure | 40 | yes |
| 40P01 | deadlock detected | 40 | yes |
| 42501 | insufficient privilege | 42 | no |
| 42601 | syntax error | 42 | no |
| 42703 | undefined column | 42 | no |
| 42704 | undefined object | 42 | no |
| 42710 | duplicate object | 42 | no |
| 42883 | undefined function | 42 | no |
| 42P01 | undefined table | 42 | no |
| 42P07 | duplicate table | 42 | no |
| 53P00 | configuration limit exceeded | 53 | no |
| 53100 | disk full | 53 | no |
| 53200 | out of memory | 53 | no |
| 53300 | too many connections | 53 | no |
| 54000 | program limit exceeded | 54 | no |
| 57014 | query canceled | 57 | yes |
| 57P01 | admin shutdown | 57 | no |
| 57P03 | cannot connect now | 57 | yes |
| 58000 | system error | 58 | no |
| XX000 | internal error | XX | no |

## Per-Language Mapping

### Go

- error type: *scratchbird.Error
- sqlstate class mapping: mapSQLState

### Node.js/TypeScript

- error types: ScratchbirdError subclasses
- sqlstate class mapping: mapSqlState

### Python

- 08xxx -> OperationalError
- 28xxx -> OperationalError
- 22xxx -> DataError
- 23xxx -> IntegrityError
- 42xxx -> ProgrammingError
- 0Axxx -> NotSupportedError
- 57xxx -> OperationalError
- XXxxx -> InternalError

### Ruby

- error types: Scratchbird::Error subclasses
- sqlstate class mapping: ErrorMapper.from_sqlstate

### Rust

- error type: Error with ErrorKind
- sqlstate class mapping: error_from_sqlstate

### PHP

- error types: ScratchBirdException subclasses
- sqlstate class mapping: ErrorMapper::map

### R

- raise error with sqlstate prefix in message

### Pascal/Delphi

- error types: EScratchBirdError subclasses
- sqlstate class mapping: MapSqlState

### .NET

- error types: ScratchBirdException subclasses
- sqlstate class mapping: ScratchBirdSqlStateMapper.Create

### JDBC

- java.sql.SQLException with SQLState set
