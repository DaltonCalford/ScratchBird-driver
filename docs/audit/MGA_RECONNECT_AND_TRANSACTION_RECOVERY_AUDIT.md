# ScratchBird Driver MGA Reconnect And Transaction Recovery Audit

This note defines how ScratchBird drivers participate in recovery when the engine itself is MGA/state based.

## Driver Rule

Drivers do not perform WAL-style transaction replay.

They are responsible for:

- reconnecting transport/session state when the connection is lost
- resetting local client state after disconnect or cancel
- issuing explicit rollback/reset/retry when the protocol and API contract allow it
- resuming result delivery only for explicit suspended/portal-resume protocol states

They must not assume that reconnect resurrects an in-flight transaction or replays lost statements.

## Why

ScratchBird engine truth lives in MGA state, not a redo log. After disconnect or crash:

- committed truth is recovered by the engine from TIP/CLOG, page state, and checkpoint markers
- uncommitted work is finalized by engine recovery rules
- client libraries may reopen sessions and retry operations, but they do not reconstruct transaction history

## Audit Entry Points By Lane

Baseline-mapped lanes:

- `tracks/p3/drivers/cli/BASELINE_REQUIREMENT_MAPPING.md`
- `tracks/p3/drivers/cpp/BASELINE_REQUIREMENT_MAPPING.md`
- `tracks/p3/drivers/dart/BASELINE_REQUIREMENT_MAPPING.md`
- `tracks/p3/drivers/dotnet/BASELINE_REQUIREMENT_MAPPING.md`
- `tracks/p3/drivers/go/BASELINE_REQUIREMENT_MAPPING.md`
- `tracks/p3/drivers/jdbc/BASELINE_REQUIREMENT_MAPPING.md`
- `tracks/p3/drivers/mojo/BASELINE_REQUIREMENT_MAPPING.md`
- `tracks/p3/drivers/node/BASELINE_REQUIREMENT_MAPPING.md`
- `tracks/p3/drivers/odbc/BASELINE_REQUIREMENT_MAPPING.md`
- `tracks/p3/drivers/pascal/BASELINE_REQUIREMENT_MAPPING.md`
- `tracks/p3/drivers/php/BASELINE_REQUIREMENT_MAPPING.md`
- `tracks/p3/drivers/python/BASELINE_REQUIREMENT_MAPPING.md`
- `tracks/p3/drivers/r/BASELINE_REQUIREMENT_MAPPING.md`
- `tracks/p3/drivers/ruby/BASELINE_REQUIREMENT_MAPPING.md`
- `tracks/p3/drivers/rust/BASELINE_REQUIREMENT_MAPPING.md`
- `tracks/p3/drivers/swift/BASELINE_REQUIREMENT_MAPPING.md`

Specialty lane with direct README/test anchors:

- `tracks/p3/drivers/elixir/README.md`

## Representative Runtime Anchors

The following files show the live reconnect/recovery behavior that the lane mappings point at:

- JDBC transport and failover reconnect: `tracks/p3/drivers/jdbc/src/main/java/com/scratchbird/jdbc/SBConnection.java`
- JDBC pool recovery: `tracks/p3/drivers/jdbc/src/main/java/com/scratchbird/jdbc/SBConnectionPool.java`
- .NET reconnect / keepalive recovery: `tracks/p3/drivers/dotnet/src/ScratchBird.Data/ScratchBirdConnection.cs`
- .NET transport reset semantics: `tracks/p3/drivers/dotnet/src/ScratchBird.Data/ProtocolClient.cs`
- C/C++ retry and pool reconnect: `tracks/p3/drivers/cpp/src/pool.cpp`
- ODBC retry helpers: `tracks/p3/drivers/odbc/src/statement_cache.cpp`
- Python retry / circuit-breaker / pool recovery: `tracks/p3/drivers/python/src/scratchbird/pool.py`, `tracks/p3/drivers/python/src/scratchbird/circuit_breaker.py`
- R reconnect-required state handling: `tracks/p3/drivers/r/R/client.R`
- Mojo reconnect-required state handling: `tracks/p3/drivers/mojo/src/scratchbird.py`

## Contract Summary

For auditors, the intended interpretation is:

- engine recovery is MGA and authoritative
- drivers repair client connectivity and session state
- transaction recovery at the driver layer means reset, rollback, reopen, or retry against engine truth
- no driver is expected to implement WAL replay

That separation is required so every driver stays aligned to the same engine model.
