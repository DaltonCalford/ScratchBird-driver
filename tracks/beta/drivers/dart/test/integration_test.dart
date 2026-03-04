import 'dart:io';

import 'package:scratchbird/scratchbird.dart';
import 'package:test/test.dart';

final String? _testDsn = Platform.environment['SCRATCHBIRD_TEST_DSN'];
final String? _integrationSkipReason =
    (_testDsn == null || _testDsn!.trim().isEmpty)
        ? 'SCRATCHBIRD_TEST_DSN not set'
        : null;

ScratchBirdConfig _integrationConfig() {
  final dsn = _testDsn;
  if (dsn == null || dsn.trim().isEmpty) {
    throw StateError('SCRATCHBIRD_TEST_DSN not set');
  }
  return ScratchBirdConfig.fromDsn(dsn);
}

Future<ScratchBirdClient> _connectClient() {
  return ScratchBirdClient.connect(_integrationConfig());
}

void main() {
  test(
    'integration connect and basic query',
    () async {
      final client = await _connectClient();
      try {
        final result = await client.query('SELECT 1');
        expect(result.rows, isNotEmpty);
        expect(result.rows.first, isNotEmpty);
        expect(result.rows.first.first, equals(1));
      } finally {
        await client.close();
      }
    },
    skip: _integrationSkipReason,
  );

  test(
    'integration parameterized query',
    () async {
      final client = await _connectClient();
      try {
        final result = await client.query('SELECT ?::INTEGER', <dynamic>[42]);
        expect(result.rows, isNotEmpty);
        expect(result.rows.first, isNotEmpty);
        expect(result.rows.first.first, equals(42));
      } finally {
        await client.close();
      }
    },
    skip: _integrationSkipReason,
  );

  test(
    'integration type roundtrip',
    () async {
      final client = await _connectClient();
      try {
        final result = await client.query(
          'SELECT ?::INTEGER, ?::DOUBLE, ?::VARCHAR, ?::BOOLEAN',
          <dynamic>[42, 3.5, 'scratchbird-dart', true],
        );
        expect(result.rows, isNotEmpty);
        expect(result.rows.first,
            equals(<dynamic>[42, 3.5, 'scratchbird-dart', true]));
      } finally {
        await client.close();
      }
    },
    skip: _integrationSkipReason,
  );

  test(
    'integration transaction begin/commit/rollback cycle',
    () async {
      final client = await _connectClient();
      try {
        await client.begin();
        await client.commit();
        await client.begin();
        await client.rollback();
      } finally {
        await client.close();
      }
    },
    skip: _integrationSkipReason,
  );

  test(
    'integration metadata wrappers',
    () async {
      final client = await _connectClient();
      try {
        final result = await client.queryMetadata('schemas');
        expect(result.columns, isNotEmpty);

        final schemaRows = await client.getSchema(collectionName: 'schemas');
        expect(schemaRows, isA<List<Map<String, dynamic>>>());

        final tree = await client.getSchemaTree(expandParents: true);
        expect(tree.database, equals(_integrationConfig().database));
      } finally {
        await client.close();
      }
    },
    skip: _integrationSkipReason,
  );
}
