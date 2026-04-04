# Ruby Driver

<!-- lane-status:start -->
## Current Status

- Lane kind: `driver`
- Current state: `baseline_complete`
- Best-in-class benchmark: `ruby-pg`
- Authoritative lane spec: `docs/specifications/drivers/language/ruby/SPECIFICATION.md`
- Shared release evidence templates: `docs/development/release-evidence/README.md`
- Later verification packet: `docs/development/server-verification/ruby.md`
- Remaining gap summary: No lane-local JDBC/.NET-class baseline gaps remain. Remaining work is live proof collection and release evidence staging.
<!-- lane-status:end -->

## Install

```bash
gem build tracks/p3/drivers/ruby/scratchbird.gemspec
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
- Manager-proxy and auth-plugin startup keys are supported.

## Tests

Integration tests are gated by:

- `SCRATCHBIRD_RUBY_URL`
