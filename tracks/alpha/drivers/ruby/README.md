# ScratchBird Ruby Driver

Native ScratchBird Ruby driver using the ScratchBird wire protocol.

## Documentation

- Getting started: `docs/getting-started/ruby.md`
- API reference: `docs/api-reference/ruby.md`

## Build/Test (Windows/Linux)

See `docs/BUILD_MATRIX.md`.

## Installation

```bash
gem build scratchbird.gemspec
gem install scratchbird-0.1.0.gem
```

## Usage

```ruby
require "scratchbird"

conn = Scratchbird.connect("scratchbird://user:pass@localhost:3092/mydb")
result = conn.query("SELECT 1 AS one")
puts result.first[0]
conn.close
```

## Connection strings

URI:

```
scratchbird://user:password@host:3092/database?sslmode=require
```

Key-value:

```
host=localhost port=3092 dbname=mydb user=myuser password=mypass
```
