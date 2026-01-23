# ScratchBird Node.js/TypeScript Driver

Native ScratchBird driver for Node.js with full TypeScript types.

## Documentation

- Getting started: `docs/getting-started/node.md`
- API reference: `docs/api-reference/node.md`

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
npm test
```

Integration test:

```bash
export SCRATCHBIRD_NODE_URL="scratchbird://user:pass@localhost:3092/db"
node --test node/test/integration.test.js
```
