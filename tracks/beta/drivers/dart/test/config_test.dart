// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

import 'package:test/test.dart';
import 'package:scratchbird/scratchbird.dart';

void main() {
  test('parses dsn', () {
    final cfg = ScratchBirdConfig.fromDsn('scratchbird://user:pass@localhost:3092/db');
    expect(cfg.user, 'user');
    expect(cfg.password, 'pass');
    expect(cfg.database, 'db');
  });

  test('parses manager proxy params', () {
    final cfg = ScratchBirdConfig.fromDsn(
      'scratchbird://admin:secret@localhost:3090/mydb?front_door_mode=manager_proxy&manager_auth_token=token&manager_client_flags=7',
    );
    expect(cfg.frontDoorMode, 'manager_proxy');
    expect(cfg.managerAuthToken, 'token');
    expect(cfg.managerClientFlags, 7);
  });

  test('rejects invalid front door mode', () {
    expect(
      () => ScratchBirdConfig.fromDsn(
        'scratchbird://localhost:3092/db?front_door_mode=invalid',
      ),
      throwsArgumentError,
    );
  });
}
