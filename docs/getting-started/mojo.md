# Mojo Driver

## Install

The Mojo driver lives in `tracks/p3/drivers/mojo/` and uses the ScratchBird Python driver as a
transport bridge until Mojo networking APIs stabilize.

Install the Mojo toolchain (see `docs/development/toolchain-setup.md` for
recommended Pixi-based setup).

Required:

- Python 3.10+
- `scratchbird` Python package on `PYTHONPATH`

## Status

- SBWP v1.1 API surface is available through Mojo-Python interop (not a native SBWP client).
- Native transport replacement is planned once Mojo networking is stable.

## Tests

Use the shared conformance fixtures via the Python driver; a Mojo-native test
runner will be added once the transport bridge is replaced.
