import 'package:scratchbird/scratchbird.dart';
import 'package:scratchbird/src/scram.dart';
import 'package:test/test.dart';

void main() {
  test('scram rejects server-first nonce mismatch with auth exception', () {
    final scram = ScramClient('user');
    expect(
      () => scram.handleServerFirst(
        'password',
        'r=server_nonce,s=c2FsdA==,i=4096',
      ),
      throwsA(
        isA<ScratchBirdAuthException>().having(
          (e) => e.message,
          'message',
          contains('nonce mismatch'),
        ),
      ),
    );
  });

  test('scram rejects server-final signature mismatch with auth exception', () {
    final scram = ScramClient('user');
    expect(
      () => scram.verifyServerFinal('v=invalid'),
      throwsA(
        isA<ScratchBirdAuthException>().having(
          (e) => e.message,
          'message',
          contains('signature mismatch'),
        ),
      ),
    );
  });
}
