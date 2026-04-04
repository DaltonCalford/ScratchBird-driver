# Elixir Ecto Adapter Specification (ScratchBird)

Status: Partial
Last Updated: 2026-04-03

## Implementation Status

- Current lane verdict: partial against the lane-local JDBC/.NET-class baseline mapping.
- Source of truth: `tracks/p3/drivers/elixir/BASELINE_REQUIREMENT_MAPPING.md`
- Outstanding baseline gaps:
  - `EXEC`: no standalone public portal-resume helper and deterministic stream/paging proof is still limited.
  - `RES`: resilience still uses fresh-connect-only recovery rather than transparent in-place reconnect.

## Goal

Define a native Elixir Ecto adapter and DBConnection driver that speaks
ScratchBird Wire Protocol (SBWP v1.1) using binary transfer only. The adapter
must provide full Ecto SQL integration for application workloads and migrations.

## Package Layout

- Hex package: `scratchbird_ecto`
- Primary modules:
  - `ScratchBird.Ecto` (adapter entry point)
  - `ScratchBird.Ecto.Connection` (DBConnection wrapper)
  - `ScratchBird.Ecto.Types` (type helpers and wrappers)
- Dependencies:
  - `ecto_sql >= 3.11`
  - `db_connection >= 2.6`
  - `decimal >= 2.0`
  - `scratchbird` (native SBWP client library)

## Adapter Integration

- Implement `Ecto.Adapters.SQL` behavior.
- Rely on `DBConnection` pooling (do not implement a custom pool).
- Support Ecto migrations:
  - `Ecto.Migration` DDL operations must map to ScratchBird DDL.
  - `:prefix` must map to schema/search_path semantics.
- Support `Ecto.Adapters.SQL.Sandbox` for tests.

## Configuration

Accepted config keys (matching driver standard):

- `hostname`, `port`, `database`, `username`, `password`
- `sslmode`, `sslrootcert`, `sslcert`, `sslkey`, `sslpassword`
- `connect_timeout`, `socket_timeout`
- `application_name`, `search_path`, `role`
- `binary_transfer` (must be true)
- `compression` (off|zstd)
- `fetch_size`
- `pool_size`, `queue_target`, `queue_interval` (DBConnection defaults)

DSN support:

- `url: "scratchbird://user:pass@host:3092/dbname?..."`
- `url` must be merged with explicit config (explicit overrides URL).

## Querying and Prepared Statements

- All queries must use server-side prepare/bind (SBWP v1.1).
- Placeholder format: `$1, $2, ...` (Ecto standard).
- Multi-statement SQL is not allowed by default (reject with SQLSTATE 0A000).
- Streaming results must use SBWP cursor paging; expose as `Ecto.Adapters.SQL.stream/2`.

## Transaction Semantics

- Support `Repo.transaction/2` with nested savepoints.
- Provide explicit error for unsupported nesting level (SQLSTATE 0A000).
- Map `rollback` to explicit transaction abort.

## Type Mapping

Required mappings (non-exhaustive):

- `:integer` -> INT32/INT64 (auto widen)
- `:float` -> FLOAT/DOUBLE
- `:decimal` -> DECIMAL/NUMERIC
- `:binary` -> BLOB/BYTEA (binary transfer only)
- `:uuid` -> UUID
- `:utc_datetime`/`:naive_datetime` -> TIMESTAMP
- `:date` -> DATE
- `:time` -> TIME
- `:boolean` -> BOOL
- `:map` -> JSONB (see wrapper types)

Wrapper types:

- `ScratchBird.Types.Jsonb` for JSONB
- `ScratchBird.Types.Range` for RANGE
- `ScratchBird.Types.Geometry` for GEOMETRY

Ecto custom types:

- `ScratchBird.Ecto.Types.Jsonb`
- `ScratchBird.Ecto.Types.Range`
- `ScratchBird.Ecto.Types.Geometry`

## Error Handling

- Use `ScratchBird.Ecto.Error` with fields:
  - `:sqlstate`
  - `:code`
  - `:message`
  - `:detail`
- Map all protocol errors to SQLSTATE as defined in
  `docs/specifications/DRIVER_ERROR_MAPPING.md`.

## Observability

- `application_name` must be sent on startup.
- Query cancellation must translate to SBWP cancel packet.

## Conformance Tests

- Integration tests use `SCRATCHBIRD_TEST_DSN`.
- Conformance harness uses fixtures in `docs/fixtures/`.
- Must pass:
  - handshake/auth
  - prepare/bind
  - type encode/decode
  - streaming/paging
- Publish release evidence per `DRIVER_RELEASE_READINESS_EVIDENCE_CONTRACT.md`.

## Deliverables

- `scratchbird_ecto` Hex package.
- `ScratchBird.Ecto` adapter with docs and examples.
- Test suite gated by `SCRATCHBIRD_TEST_DSN`.
- Release evidence pack with compatibility, performance, known-gap, and
  packaging/cadence artifacts.

<!-- elixir-server-independent-closure:start -->

## Competitive Closure Status

- Selected benchmark: `Postgrex`
- Current state: `partial`
- Track root: `tracks/p3/drivers/elixir`

Competitive closure targets:

- freeze stream/resume, telemetry, and reconnect semantics against Postgrex-class behavior
- require both direct-driver and Ecto evidence in the release pack

Remaining implementation or proof deltas:

- EXEC: no standalone public portal-resume helper and deterministic stream/paging proof remains limited
- RES: resilience still uses fresh-connect-only recovery rather than transparent in-place reconnect

## Release Evidence And Later Verification

Release evidence path:

- `release/readiness/elixir/<version>/`

Shared evidence templates:

- `docs/development/release-evidence/README.md`

Later server-verification packet:

- `docs/development/server-verification/elixir.md`

Required environment inputs:

- `SCRATCHBIRD_TEST_DSN`

Build/bootstrap commands:

- `cd tracks/p3/drivers/elixir`
- `mix local.hex --force`
- `mix local.rebar --force`
- `mix deps.get`

Verification commands:

- `mix test`

<!-- elixir-server-independent-closure:end -->
