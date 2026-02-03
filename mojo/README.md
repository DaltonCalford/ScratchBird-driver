# ScratchBird Mojo Driver

Native ScratchBird driver for Mojo (SBWP v1.1). This implementation targets
low-latency AI/ML workflows and is designed to keep the transport layer small
and swappable as Mojo networking evolves.

## Status

- Full SBWP v1.1 coverage via Mojo-Python interop (uses the ScratchBird
  Python driver for transport/auth while Mojo networking matures).
- API surface matches the canonical driver specs; transport is isolated so a
  native TCP/TLS implementation can replace the Python bridge later.

## Requirements

- Python 3.10+
- `scratchbird` Python package available on `PYTHONPATH`

## Next Steps

- Replace the Python transport bridge with native Mojo sockets/TLS
- Add Mojo-native streaming helpers and type wrappers
