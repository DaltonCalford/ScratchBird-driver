import 'dart:typed_data';

import 'package:scratchbird/scratchbird.dart';
import 'package:scratchbird/src/protocol.dart';
import 'package:test/test.dart';

ScratchBirdClient _newClient() {
  return ScratchBirdClient(
    const ScratchBirdConfig(
      host: 'localhost',
      port: 3092,
      database: 'db',
      user: 'user',
    ),
  );
}

void main() {
  group('txn guardrails', () {
    test('commit requires active transaction', () async {
      final client = _newClient();
      await expectLater(
        client.commit(),
        throwsA(
          isA<ScratchBirdTransactionException>().having(
            (e) => e.message,
            'message',
            contains('active transaction'),
          ),
        ),
      );
    });

    test('rollback requires active transaction', () async {
      final client = _newClient();
      await expectLater(
        client.rollback(),
        throwsA(
          isA<ScratchBirdTransactionException>().having(
            (e) => e.message,
            'message',
            contains('active transaction'),
          ),
        ),
      );
    });

    test('savepoint requires active transaction', () async {
      final client = _newClient();
      await expectLater(
        client.savepoint('sp1'),
        throwsA(
          isA<ScratchBirdTransactionException>().having(
            (e) => e.message,
            'message',
            contains('active transaction'),
          ),
        ),
      );
    });
  });

  group('txn payload encoding', () {
    test('begin payload encodes flags and options', () {
      const flags = txnFlagHasIsolation |
          txnFlagHasAccess |
          txnFlagHasDeferrable |
          txnFlagHasWait |
          txnFlagHasTimeout |
          txnFlagHasAutocommit;
      final payload = buildTxnBeginPayload(
        flags,
        2,
        1,
        isolationSerializable,
        1,
        1,
        0,
        1500,
      );
      final data = ByteData.sublistView(payload);
      expect(data.getUint16(0, Endian.little), equals(flags));
      expect(data.getUint8(2), equals(2));
      expect(data.getUint8(3), equals(1));
      expect(data.getUint8(4), equals(isolationSerializable));
      expect(data.getUint8(5), equals(1));
      expect(data.getUint8(6), equals(1));
      expect(data.getUint8(7), equals(0));
      expect(data.getUint32(8, Endian.little), equals(1500));
    });

    test('savepoint payloads preserve savepoint name bytes', () {
      final savepoint = buildTxnSavepointPayload('sp_1');
      final release = buildTxnReleasePayload('sp_1');
      final rollbackTo = buildTxnRollbackToPayload('sp_1');
      expect(release, equals(savepoint));
      expect(rollbackTo, equals(savepoint));
      final data = ByteData.sublistView(savepoint);
      expect(data.getUint32(0, Endian.little), equals(4));
      expect(String.fromCharCodes(savepoint.sublist(4)), equals('sp_1'));
    });
  });

  group('exec guardrails', () {
    test('query rejects empty SQL', () async {
      final client = _newClient();
      await expectLater(
        client.query('   '),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('SQL text must not be empty'),
          ),
        ),
      );
    });

    test('cancel rejects when no active query sequence', () async {
      final client = _newClient();
      await expectLater(
        client.cancel(),
        throwsA(
          isA<ScratchBirdExecutionException>().having(
            (e) => e.message,
            'message',
            contains('No active query to cancel'),
          ),
        ),
      );
    });
  });

  group('exec payload encoding', () {
    test('query payload encodes flags, limits, timeout, and SQL', () {
      final payload = buildQueryPayload(
        'SELECT 42',
        queryFlagBinaryResult | queryFlagIncludePlan,
        25,
        900,
      );
      final data = ByteData.sublistView(payload);
      expect(
        data.getUint32(0, Endian.little),
        equals(queryFlagBinaryResult | queryFlagIncludePlan),
      );
      expect(data.getUint32(4, Endian.little), equals(25));
      expect(data.getUint32(8, Endian.little), equals(900));
      final sql = payload.sublist(12);
      expect(sql.last, equals(0));
      expect(
        String.fromCharCodes(sql.sublist(0, sql.length - 1)),
        equals('SELECT 42'),
      );
    });

    test('execute payload encodes portal and max rows', () {
      final payload = buildExecutePayload('portal_1', 128);
      final data = ByteData.sublistView(payload);
      final portalLength = data.getUint32(0, Endian.little);
      expect(portalLength, equals(8));
      expect(String.fromCharCodes(payload.sublist(4, 12)), equals('portal_1'));
      expect(data.getUint32(12, Endian.little), equals(128));
    });

    test('cancel payload encodes type and target sequence', () {
      final payload = buildCancelPayload(0, 77);
      final data = ByteData.sublistView(payload);
      expect(data.getUint32(0, Endian.little), equals(0));
      expect(data.getUint32(4, Endian.little), equals(77));
    });
  });
}
