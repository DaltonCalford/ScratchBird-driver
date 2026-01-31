# ScratchBird Driver Specifications

This directory contains implementation requirements for the native ScratchBird drivers.
The authoritative protocol reference lives in the main ScratchBird repo and is linked
from each spec below.

## Specifications

- [NATIVE_PROTOCOL_ALIGNMENT.md](NATIVE_PROTOCOL_ALIGNMENT.md) - SBWP v1.1 client requirements
- [PREPARE_BIND_REQUIREMENTS.md](PREPARE_BIND_REQUIREMENTS.md) - Server-side prepare/bind rules
- [TYPE_MAPPING_MATRIX.md](TYPE_MAPPING_MATRIX.md) - Required type coverage and conversions
- [METADATA_SCHEMA_CONTRACT.md](METADATA_SCHEMA_CONTRACT.md) - Schema/search path + metadata queries
- [DRIVER_MONITORING_VIEW_SUPPORT.md](DRIVER_MONITORING_VIEW_SUPPORT.md) - sys.* monitoring view support
- [DRIVER_CONFORMANCE_TEST_HARNESS.md](DRIVER_CONFORMANCE_TEST_HARNESS.md) - Shared test harness contract
- [DRIVER_DSN_AND_CONFIG_STANDARD.md](DRIVER_DSN_AND_CONFIG_STANDARD.md) - Canonical DSN and config keys
- [DRIVER_AUTHENTICATION_MAPPING.md](DRIVER_AUTHENTICATION_MAPPING.md) - Auth method mapping
- [DRIVER_ERROR_MAPPING.md](DRIVER_ERROR_MAPPING.md) - SQLSTATE and error handling rules
- [DRIVER_PARAMETER_ENCODING.md](DRIVER_PARAMETER_ENCODING.md) - Parameter encoding rules
- [DRIVER_RESULT_DECODING.md](DRIVER_RESULT_DECODING.md) - Result decoding requirements
- [DRIVER_CANCELLATION_TIMEOUTS.md](DRIVER_CANCELLATION_TIMEOUTS.md) - Cancel/timeout behavior
- [DRIVER_STREAMING_AND_PAGING.md](DRIVER_STREAMING_AND_PAGING.md) - Streaming and paging rules
- [DRIVER_METADATA_JDBC_ODBC_MAPPING.md](DRIVER_METADATA_JDBC_ODBC_MAPPING.md) - JDBC/ODBC metadata mapping
- [DRIVER_THREAD_SAFETY_POOLING.md](DRIVER_THREAD_SAFETY_POOLING.md) - Thread safety and pooling
- [DRIVER_SERVER_FEATURE_GAPS_AND_EXTENSIONS.md](DRIVER_SERVER_FEATURE_GAPS_AND_EXTENSIONS.md) - Server features drivers can leverage
- [DRIVER_ELIXIR_ECTO_ADAPTER.md](DRIVER_ELIXIR_ECTO_ADAPTER.md) - Elixir Ecto adapter requirements
- [DRIVER_SWIFT_ASYNC_ADAPTER.md](DRIVER_SWIFT_ASYNC_ADAPTER.md) - Swift async/await driver requirements
- [DRIVER_DART_DATABASE_API.md](DRIVER_DART_DATABASE_API.md) - Dart database API requirements
- [DRIVER_MOJO_NATIVE_API.md](DRIVER_MOJO_NATIVE_API.md) - Mojo native driver requirements

## Related Specs (ScratchBird)

- ScratchBird native wire protocol: `ScratchBird/docs/specifications/wire_protocols/scratchbird_native_wire_protocol.md`
- System catalog overview: `ScratchBird/docs/specifications/catalog/README.md`
- Schema path rules: `ScratchBird/docs/specifications/catalog/SCHEMA_PATH_RESOLUTION.md`
