# ScratchBird Node.js/TypeScript Driver

Native ScratchBird driver for Node.js with full TypeScript types.

## Documentation

- [Getting started](../../../../docs/getting-started/node.md)
- [API reference](../../../../docs/api-reference/node.md)
- Baseline requirement mapping: [`BASELINE_REQUIREMENT_MAPPING.md`](BASELINE_REQUIREMENT_MAPPING.md)

## MGA Recovery Contract

This lane follows ScratchBird's MGA/state-based engine recovery model.

- reconnect or reopen only repairs transport and session state
- reconnect never resurrects abandoned in-flight transactions or replay lost statements
- transaction recovery in the lane means reset, rollback, reopen, or retry against engine truth
- result resume is valid only for explicit suspended protocol states
- the internal portal-resume path now fails closed with `55000` unless the
  server first reported `PORTAL_SUSPENDED`
- same-client reconnect discards prepared handles, attachment parameters, and
  cached plan/SBLR frames from the abandoned session before the new handshake
- `prepareTransaction(...)`, `commitPrepared(...)`, and
  `rollbackPrepared(...)` expose explicit prepared/limbo control through
  canonical transaction-control SQL rather than reconnect heuristics
- `supportsDormantReattach()` is explicit and false, and
  `detachToDormant()` / `reattachDormant()` fail closed with `0A000` until a
  public dormant front-door exists
- `beginTransaction(options)` exposes the canonical MGA begin flags for
  `isolationLevel`, `accessMode`, `deferrable`, `wait`, `timeoutMs`,
  `autocommitMode`, `conflictAction`, and `readCommittedMode`
- native `READY`, `TXN_STATUS`, and `current_txn_id` are treated as
  authoritative transaction-state surfaces, so a fresh native session
  boundary can remain active with `txn_id == 0`
- native autocommit transitions stay local to the wrapper instead of sending
  `SET_OPTION autocommit` or a synthetic replacement `BEGIN`
- current isolation alias mapping is explicit in lane source:
  `READ COMMITTED` => canonical `READ COMMITTED`,
  `REPEATABLE READ` => canonical `SNAPSHOT`,
  `SERIALIZABLE` => canonical `SNAPSHOT TABLE STABILITY`
- the public `READ_COMMITTED_MODE_*` constants plus
  `canonicalReadCommittedModeLabel(...)` make the canonical `READ COMMITTED`
  sub-modes explicit in lane source; `readCommittedMode` now exposes
  `READ COMMITTED READ CONSISTENCY` directly
- `retryScopeForSqlState(...)` makes the retry boundary explicit:
  `40001`/`40P01` => fresh statement only, `08xxx` => reconnect or reopen
  only, everything else => no automatic replay

See `../../../../docs/audit/MGA_RECONNECT_AND_TRANSACTION_RECOVERY_AUDIT.md`.

## Build/Test (Windows/Linux)

See `docs/BUILD_MATRIX.md`.

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Linux | Supported | CI build/test coverage. |
| Windows | Supported | CI build/test coverage. |
| macOS | Untested | Not currently covered in CI. |

## Install

```bash
npm install scratchbird
```

## Usage

```ts
import { Client } from "scratchbird";

const client = new Client({
  host: "localhost",
  port: 3092,
  user: "user",
  password: "pass",
  database: "db",
});

await client.connect();
const res = await client.query("select 1 as one");
console.log(res.rows);
await client.end();
```

## SSL/TLS

```ts
const client = new Client({
  host: "localhost",
  user: "user",
  password: "pass",
  database: "db",
  sslmode: "verify-full",
  sslrootcert: "/etc/ssl/certs/ca.pem",
});
```

## Tests

```bash
npm install
npm test
```

Integration test:

```bash
export SCRATCHBIRD_NODE_URL="scratchbird://user:pass@localhost:3092/db"
node --test node/test/integration.test.js
```
