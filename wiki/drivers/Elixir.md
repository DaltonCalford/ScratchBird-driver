[Back to Drivers](Driver-Comparison.md) | [Back to Home](../Home.md)

# Elixir (Ecto) Driver Guide

**Status:** Preview (SBWP v1.1 baseline)
**Last Updated:** 2026-02-02

---

## Overview

Native ScratchBird driver with Ecto adapter (SBWP v1.1).

## Install

```bash
cd elixir
mix deps.get
```

## Quick Start

```elixir
{:ok, conn} = ScratchBird.Connection.connect(
  url: "scratchbird://user:pass@localhost:3092/mydb"
)
{:ok, result} = ScratchBird.Connection.query(conn, "SELECT 1", [])
IO.inspect(result.rows)
```

## Documentation

- [Getting started](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/getting-started/elixir.md)
- [API reference](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/api-reference/elixir.md)
- [Driver README](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/elixir/README.md)

## Configuration

See [DSN and config standard](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/specifications/DRIVER_DSN_AND_CONFIG_STANDARD.md).

## Testing

Integration tests use `SCRATCHBIRD_TEST_DSN`.

