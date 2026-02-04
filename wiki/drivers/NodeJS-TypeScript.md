[Back to Drivers](Driver-Comparison.md) | [Back to Home](../Home.md)

# Node.js / TypeScript Driver Guide

**Status:** Alpha track (SBWP v1.1 baseline)
**Last Updated:** 2026-02-04

---

## Overview

Native ScratchBird driver for Node.js with full TypeScript types.

## Install

```bash
npm install scratchbird
```

## Quick Start

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
const res = await client.query("SELECT 1 AS one");
console.log(res.rows);
await client.end();
```

## Documentation

- [Getting started](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/getting-started/node.md)
- [API reference](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/api-reference/node.md)
- [Driver README](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/tracks/alpha/drivers/node/README.md)

## Configuration

See [DSN and config standard](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/specifications/DRIVER_DSN_AND_CONFIG_STANDARD.md).

## Testing

Integration tests use `SCRATCHBIRD_NODE_URL`.

