# Dart Driver

## Status

Partial SBWP v1.1 implementation. TLS/binary-only enforcement and zstd rejection are implemented; metadata helpers and full type coverage are still incomplete.

## Install

Install the Dart SDK (see `docs/development/toolchain-setup.md` for Ubuntu 24.04
steps).

```bash
cd tracks/p3/drivers/dart
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

## Tests

Integration tests use:

- `SCRATCHBIRD_TEST_DSN`
