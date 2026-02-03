# Dart Driver

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

## Tests

Integration tests use:

- `SCRATCHBIRD_TEST_DSN`
