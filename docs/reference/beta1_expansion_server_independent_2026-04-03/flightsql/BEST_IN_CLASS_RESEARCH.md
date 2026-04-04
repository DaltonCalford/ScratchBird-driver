# Flight SQL Best-In-Class Research

Status: Current
Lane: `flightsql`
Benchmark: `Apache Arrow Flight SQL client stack`

## Why This Benchmark

Flight SQL is the strongest open benchmark for a high-throughput analytical SQL
client path built on Arrow Flight. It defines the expectation set for:

- query execution over Flight SQL tickets and streams
- prepared statements and metadata discovery
- Arrow-native partitioned reads
- analytical export and ingest flows

## Official Sources

- Flight SQL format docs:
  `https://arrow.apache.org/docs/format/FlightSql.html`
- Implementation anchor:
  `https://github.com/apache/arrow`

## Capability Families That Become Non-Optional

- Flight SQL protocol conformance over ScratchBird session/auth semantics
- prepared statement lifecycle and parameter binding
- metadata discovery and cancellation operations
- partitioned execution and Arrow stream handling
- TLS/channel/auth configuration suitable for analytical clients

## ScratchBird Implementation Implications

- the lane needs a first-class analytical transport, not a JDBC bridge in
  disguise
- metadata and error semantics must remain predictable when mapped into the
  Flight SQL model
- the transport design must preserve MGA/session correctness while allowing
  high-throughput result streaming

## Later Server Validation Focus

- query and prepared-statement correctness over Flight SQL
- Arrow stream integrity and partitioned read behavior
- cancellation and channel-options behavior
- interoperability with Arrow client tooling
