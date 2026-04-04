# Dart Driver

<!-- lane-status:start -->
## Current Status

- Lane kind: `driver`
- Current state: `partial`
- Best-in-class benchmark: `postgres (Dart)`
- Authoritative lane spec: `docs/specifications/DRIVER_DART_DATABASE_API.md`
- Shared release evidence templates: `docs/development/release-evidence/README.md`
- Later verification packet: `docs/development/server-verification/dart.md`
- Remaining gap summary: Live TXN failure-path validation, pagination/portal-suspend coverage, richer metadata families, complex-type roundtrips, and resilience cleanup proof remain open.
<!-- lane-status:end -->

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
