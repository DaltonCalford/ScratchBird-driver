// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

import 'dart:io';

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
  test('connect allows sslmode=disable and reaches the socket layer', () async {
    final cfg =
        _baseConfig(sslmode: 'disable').copyWith(host: '127.0.0.1', port: 1);
    await expectLater(
      ScratchBirdClient.connect(cfg),
      throwsA(
        anyOf(
          isA<SocketException>(),
          isA<ScratchBirdConnectionException>().having(
            (e) => e.toString(),
            'message',
            isNot(contains('TLS is required')),
          ),
        ),
      ),
    );
  });

  test('connect rejects binary_transfer=false', () async {
    final cfg = _baseConfig(binaryTransfer: false);
    await expectLater(
      ScratchBirdClient.connect(cfg),
      throwsA(
        isA<ScratchBirdConnectionException>().having(
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
        isA<ScratchBirdConnectionException>().having(
          (e) => e.toString(),
          'message',
          contains('compression=zstd is not supported'),
        ),
      ),
    );
  });
}
