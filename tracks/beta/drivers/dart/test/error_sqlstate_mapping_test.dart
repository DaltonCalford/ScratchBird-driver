import 'package:scratchbird/scratchbird.dart';
import 'package:test/test.dart';

void main() {
  test('sqlstate 23505 maps to integrity exception', () {
    final ex = mapSqlStateExecutionException(
      'duplicate key',
      sqlState: '23505',
      code: 321,
    );
    expect(ex, isA<ScratchBirdIntegrityException>());
    expect(ex.sqlState, equals('23505'));
    expect(ex.code, equals(321));
  });

  test('sqlstate class 22 maps to data exception', () {
    final ex = mapSqlStateExecutionException(
      'invalid text representation',
      sqlState: '22P02',
    );
    expect(ex, isA<ScratchBirdDataException>());
    expect(ex.sqlState, equals('22P02'));
  });

  test('sqlstate class 42 maps to programming exception', () {
    final ex = mapSqlStateExecutionException(
      'relation does not exist',
      sqlState: '42P01',
    );
    expect(ex, isA<ScratchBirdProgrammingException>());
    expect(ex.sqlState, equals('42P01'));
  });

  test('sqlstate class 08 maps to operational exception', () {
    final ex = mapSqlStateExecutionException(
      'connection failure',
      sqlState: '08006',
    );
    expect(ex, isA<ScratchBirdOperationalException>());
    expect(ex.sqlState, equals('08006'));
  });

  test('empty sqlstate falls back to generic execution exception', () {
    final ex = mapSqlStateExecutionException('query failed');
    expect(ex, isA<ScratchBirdExecutionException>());
    expect(ex, isNot(isA<ScratchBirdDataException>()));
    expect(ex.sqlState, isNull);
  });
}
