# Node.js Driver

<!-- lane-status:start -->
## Current Status

- Lane kind: `driver`
- Current state: `baseline_complete`
- Best-in-class benchmark: `node-postgres`
- Authoritative lane spec: `docs/specifications/drivers/language/nodejs-typescript/SPECIFICATION.md`
- Shared release evidence templates: `docs/development/release-evidence/README.md`
- Later verification packet: `docs/development/server-verification/node.md`
- Remaining gap summary: No lane-local JDBC/.NET-class baseline gaps remain. Remaining work is live proof collection and release evidence staging.
<!-- lane-status:end -->

## Install

For repo-local development:

```bash
cd tracks/p3/drivers/node
npm install
npm run build
```

## Quick Start

```ts
import { Client } from "scratchbird";

const client = new Client({
  host: "localhost",
  port: 3092,
  user: "user",
  password: "pass",
  database: "mydb",
});

await client.connect();
const res = await client.query("SELECT 1 AS one");
console.log(res.rows);
await client.end();
```

## Connection Strings

Direct/native:

```
scratchbird://user:password@host:3092/database?sslmode=prefer
```

Manager-proxy:

```
scratchbird://user:password@host:3090/database?front_door_mode=manager_proxy&manager_auth_token=token
```

Current lane behavior:

- Direct DSNs accept the standard `sslmode` values, including `disable`.
- Compatibility startup keys include `binary_transfer=false` and
  `compression=zstd|none|off`.
- Managed ingress and auth-plugin startup keys are supported:
  `client_flags|connect_client_flags`, `auth_method_payload`,
  `auth_required_methods`, `auth_forbidden_methods`,
  `auth_require_channel_binding`, `workload_identity_token`, and
  `proxy_principal_assertion`.

Use TLS-enabled modes in production.

## Tests

Integration tests are gated by:

- `SCRATCHBIRD_NODE_URL`

Local test run:

```bash
cd tracks/p3/drivers/node
npm test
```
