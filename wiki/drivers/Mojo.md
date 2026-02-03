[Back to Drivers](Driver-Comparison.md) | [Back to Home](../Home.md)

# Mojo Driver Guide

**Status:** Preview (Python transport bridge)
**Last Updated:** 2026-02-02

---

## Overview

ScratchBird driver for Mojo using SBWP v1.1 via a Python transport bridge.

## Install

```text
Requires Python 3.10+ and the scratchbird Python package on PYTHONPATH.
```

## Quick Start

```text
The Mojo driver uses Python interop for transport while Mojo networking matures.
See the Getting Started link below for setup steps.
```

## Documentation

- [Getting started](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/getting-started/mojo.md)
- [API reference](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/api-reference/mojo.md)
- [Driver README](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/mojo/README.md)
- [Driver spec](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/specifications/DRIVER_MOJO_NATIVE_API.md)

## Configuration

See [DSN and config standard](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/specifications/DRIVER_DSN_AND_CONFIG_STANDARD.md).

## Testing

Integration tests use `SCRATCHBIRD_TEST_DSN` via the Python transport.

