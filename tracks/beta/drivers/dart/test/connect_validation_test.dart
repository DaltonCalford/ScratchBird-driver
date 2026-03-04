// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

import 'package:scratchbird/scratchbird.dart';
import 'package:test/test.dart';

ScratchBirdConfig _baseConfig({
  String sslmode = 'require',
  bool binaryTransfer = true,
  String compression = 'off',
}) {
  return ScratchBirdConfig(
    host: 'localhost',
    port: 3092,
    database: 'db',
    user: 'user',
    sslmode: sslmode,
    binaryTransfer: binaryTransfer,
    compression: compression,
  );
}

void main() {
  test('connect rejects sslmode=disable', () async {
    final cfg = _baseConfig(sslmode: 'disable');
    await expectLater(
      ScratchBirdClient.connect(cfg),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('TLS is required'),
        ),
      ),
    );
  });

  test('connect rejects binary_transfer=false', () async {
    final cfg = _baseConfig(binaryTransfer: false);
    await expectLater(
      ScratchBirdClient.connect(cfg),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('binary_transfer=false is not supported'),
        ),
      ),
    );
  });

  test('connect rejects compression=zstd', () async {
    final cfg = _baseConfig(compression: 'zstd');
    await expectLater(
      ScratchBirdClient.connect(cfg),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('compression=zstd is not supported'),
        ),
      ),
    );
  });
}
