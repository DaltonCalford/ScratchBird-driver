[Back to Drivers](Driver-Comparison.md) | [Back to Home](../Home.md)

# Dart Driver Guide

**Status:** In development (post-`0.1.0`) (partial SBWP v1.1; TLS/binary-only enforced, zstd rejected)
**Last Updated:** 2026-02-18

---

## Overview

Native Dart/Flutter driver for ScratchBird using SBWP v1.1 (partial).

## Install

Install the Dart SDK (see `docs/development/toolchain-setup.md` for Ubuntu 24.04).

```bash
cd tracks/beta/drivers/dart
dart pub get
```

## Quick Start

```dart
import 'package:scratchbird/scratchbird.dart';

final config = ScratchBirdConfig.fromDsn(
  'scratchbird://user:pass@localhost:3092/mydb',
);
final client = await ScratchBirdClient.connect(config);
final result = await client.query('SELECT 1');
print(result.rows);
await client.close();
```

## Documentation

- [Getting started](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/getting-started/dart.md)
- [API reference](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/api-reference/dart.md)
- [Driver README](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/tracks/beta/drivers/dart/README.md)

## Configuration

See [DSN and config standard](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/specifications/DRIVER_DSN_AND_CONFIG_STANDARD.md).

## Testing

Integration tests use `SCRATCHBIRD_TEST_DSN`.
