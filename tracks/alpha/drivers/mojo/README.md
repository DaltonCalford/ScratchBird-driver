# ScratchBird Mojo Driver

Native ScratchBird driver for Mojo (SBWP v1.1). This implementation targets
low-latency application workflows and is designed to keep the transport layer small
and swappable as Mojo networking evolves.

## Lane Docs

- [Baseline Requirement Mapping (S0)](BASELINE_REQUIREMENT_MAPPING.md)
- [Tests](tests/README.md)

## Status

- Full SBWP v1.1 coverage via Mojo-Python interop (uses the ScratchBird
  Python driver for transport/auth while Mojo networking matures).
- API surface matches the canonical driver specs; transport is isolated so a
  native TCP/TLS implementation can replace the Python bridge later.

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Linux | Experimental | CI path is gated (`MOJO_ENABLED=true`) and toolchain-dependent. |
| Windows | Not supported | No CI/toolchain path configured. |
| macOS | Not supported | No CI/toolchain path configured. |

## Requirements

- Python 3.10+
- `scratchbird` Python package available on `PYTHONPATH`

## Next Steps

- Replace the Python transport bridge with native Mojo sockets/TLS
- Add Mojo-native streaming helpers and type wrappers
