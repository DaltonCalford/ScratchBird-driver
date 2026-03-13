[Back to Drivers](Driver-Comparison.md) | [Back to Home](../Home.md)

# Ruby Driver Guide

**Status:** Initial Early Beta (`0.1.0`) (SBWP v1.1 baseline)
**Last Updated:** 2026-02-18

---

## Overview

ScratchBird native Ruby driver using SBWP v1.1.

## Install

```bash
gem build scratchbird.gemspec
gem install scratchbird-0.1.0.gem
```

## Quick Start

```ruby
require "scratchbird"

conn = Scratchbird.connect("scratchbird://user:pass@localhost:3092/mydb")
result = conn.query("SELECT 1 AS one")
puts result.first[0]
conn.close
```

## Documentation

- [Getting started](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/getting-started/ruby.md)
- [API reference](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/api-reference/ruby.md)
- [Driver README](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/tracks/p3/drivers/ruby/README.md)

## Configuration

See [DSN and config standard](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/specifications/DRIVER_DSN_AND_CONFIG_STANDARD.md).

## Testing

Integration tests use `SCRATCHBIRD_RUBY_URL`.

