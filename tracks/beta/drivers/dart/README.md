# ScratchBird Dart Driver

Native Dart/Flutter driver for ScratchBird (SBWP v1.1).

## Lane Docs

- [Baseline Requirement Mapping (S0)](./BASELINE_REQUIREMENT_MAPPING.md)

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Linux | Supported | CI build/test coverage. |
| Windows | Supported | CI build/test coverage. |
| macOS | Untested | Not currently covered in CI. |

## Install (local dev)

```bash
cd dart
dart pub get
```

## Quick Start

```dart
import 'package:scratchbird/scratchbird.dart';

Future<void> main() async {
  final config = ScratchBirdConfig.fromDsn(
    'scratchbird://user:pass@localhost:3092/mydb',
  );
  final client = await ScratchBirdClient.connect(config);
  final result = await client.query('SELECT 1');
  print(result.rows);
  await client.close();
}
```

## Tests

Integration tests use:

- `SCRATCHBIRD_TEST_DSN`
