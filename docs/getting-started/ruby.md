# Ruby Driver

## Install

```bash
gem build tracks/alpha/drivers/ruby/scratchbird.gemspec
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

URI:

```
scratchbird://user:password@host:3092/database?sslmode=require
```

Key-value:

```
host=localhost port=3092 dbname=mydb user=myuser password=mypass
```

See [DSN and config standard](../specifications/DRIVER_DSN_AND_CONFIG_STANDARD.md).

## TLS

TLS 1.3 is required. `sslmode=disable` is rejected.

## Tests

Integration tests are gated by:

- `SCRATCHBIRD_RUBY_URL`
