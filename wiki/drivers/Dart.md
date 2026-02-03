[Back to Drivers](Driver-Comparison.md) | [Back to Home](../Home.md)

# Dart Driver Guide

**Status:** Preview (SBWP v1.1 baseline)
**Last Updated:** 2026-02-02

---

## Overview

Native Dart/Flutter driver for ScratchBird using SBWP v1.1.

## Install

```bash
cd dart
flutter pub get
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
- [Driver README](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/dart/README.md)

## Configuration

See [DSN and config standard](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/specifications/DRIVER_DSN_AND_CONFIG_STANDARD.md).

## Testing

Integration tests use `SCRATCHBIRD_TEST_DSN`.

