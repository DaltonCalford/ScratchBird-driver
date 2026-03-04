import 'dart:async';
import 'dart:typed_data';

import 'package:scratchbird/scratchbird.dart';
import 'package:scratchbird/src/protocol.dart';
import 'package:test/test.dart';

MessageHeader _header({
  int type = MessageType.query,
  int flags = 0,
  int length = 0,
  int sequence = 1,
  int txnId = 0,
}) {
  return MessageHeader(
    type: type,
    flags: flags,
    length: length,
    sequence: sequence,
    attachmentId: Uint8List(16),
    txnId: txnId,
  );
}

void main() {
  group('err framing', () {
    test('decodeHeader rejects invalid header length', () {
      expect(
        () => decodeHeader(Uint8List(8)),
        throwsA(isA<Exception>()),
      );
    });

    test('decodeHeader rejects invalid protocol magic', () {
      final bytes = encodeMessage(_header(), Uint8List(0)).sublist(0, headerSize);
      final data = ByteData.sublistView(bytes);
      data.setUint32(0, 0x00000000, Endian.little);
      expect(
        () => decodeHeader(bytes),
        throwsA(isA<Exception>()),
      );
    });

    test('decodeHeader rejects unsupported protocol version', () {
      final bytes = encodeMessage(_header(), Uint8List(0)).sublist(0, headerSize);
      final data = ByteData.sublistView(bytes);
      data.setUint8(4, 99);
      data.setUint8(5, 99);
      expect(
        () => decodeHeader(bytes),
        throwsA(isA<Exception>()),
      );
    });

    test('decodeHeader rejects payloads above max message size', () {
      final bytes = encodeMessage(_header(), Uint8List(0)).sublist(0, headerSize);
      final data = ByteData.sublistView(bytes);
      data.setUint32(8, maxMessageSize + 1, Endian.little);
      expect(
        () => decodeHeader(bytes),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('res circuit breaker', () {
    test('transitions closed -> open -> halfOpen -> closed', () async {
      final breaker = CircuitBreaker(
        CircuitBreakerConfig(
          failureThreshold: 2,
          recoveryTimeoutMs: 20,
          successThreshold: 2,
          halfOpenMaxRequests: 1,
        ),
      );

      expect(breaker.state, equals(CircuitState.closed));
      expect(breaker.allowRequest(), isTrue);

      breaker.recordFailure();
      breaker.recordFailure();
      expect(breaker.state, equals(CircuitState.open));
      expect(breaker.allowRequest(), isFalse);

      await Future<void>.delayed(const Duration(milliseconds: 25));
      expect(breaker.allowRequest(), isTrue);
      expect(breaker.state, equals(CircuitState.halfOpen));
      expect(breaker.allowRequest(), isFalse);

      breaker.recordSuccess();
      expect(breaker.state, equals(CircuitState.halfOpen));
      expect(breaker.allowRequest(), isTrue);
      breaker.recordSuccess();
      expect(breaker.state, equals(CircuitState.closed));
    });

    test('halfOpen failure re-opens the circuit', () async {
      final breaker = CircuitBreaker(
        CircuitBreakerConfig(
          failureThreshold: 1,
          recoveryTimeoutMs: 10,
          successThreshold: 1,
          halfOpenMaxRequests: 1,
        ),
      );

      breaker.recordFailure();
      expect(breaker.state, equals(CircuitState.open));

      await Future<void>.delayed(const Duration(milliseconds: 15));
      expect(breaker.allowRequest(), isTrue);
      expect(breaker.state, equals(CircuitState.halfOpen));

      breaker.recordFailure();
      expect(breaker.state, equals(CircuitState.open));
    });
  });

  group('res keepalive', () {
    test('tracker marks idle validation requirement', () async {
      final tracker = KeepaliveTracker(
        KeepaliveConfig(
          intervalMs: 20,
          maxIdleBeforeCheckMs: 1,
          validationTimeoutMs: 20,
        ),
      );

      expect(tracker.needsValidation(), isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(tracker.needsValidation(), isTrue);

      tracker.markActive();
      expect(tracker.needsValidation(), isFalse);
    });

    test('manager triggers ping checks for idle connections', () async {
      final manager = KeepaliveManager(
        KeepaliveConfig(
          intervalMs: 5,
          maxIdleBeforeCheckMs: 0,
          validationTimeoutMs: 20,
        ),
      );
      final firstPing = Completer<void>();
      var pingCount = 0;

      manager.register('conn-1', () async {
        pingCount += 1;
        if (!firstPing.isCompleted) {
          firstPing.complete();
        }
        return true;
      });
      manager.start();
      await firstPing.future.timeout(const Duration(milliseconds: 250));
      manager.stop();

      expect(pingCount, greaterThanOrEqualTo(1));
    });
  });

  group('res leak detector', () {
    test('guard release is idempotent and checkin-safe', () {
      final detector = LeakDetector(
        LeakDetectionConfig(
          thresholdMs: 5,
          checkIntervalMs: 5,
          captureStackTrace: true,
        ),
      );
      final guard = detector.checkout(
        'conn-2',
        metadata: {'driver': 'dart'},
      );
      expect(() => guard.release(), returnsNormally);
      expect(() => guard.release(), returnsNormally);
      expect(() => detector.checkin('conn-2'), returnsNormally);
    });

    test('CheckoutInfo captures stack trace when enabled', () {
      final info = CheckoutInfo({'lane': 'dart'}, captureStackTrace: true);
      expect(info.stackTrace, isNotNull);
      expect(info.metadata['lane'], equals('dart'));
      expect(info.heldDurationMs(), greaterThanOrEqualTo(0));
    });
  });

  group('res telemetry', () {
    test('tracing disabled returns null spans', () {
      final cfg = TelemetryConfig()..enableTracing = false;
      final collector = TelemetryCollector(cfg);
      expect(collector.startSpan('query'), isNull);
    });

    test('metrics record success and failure query outcomes', () async {
      final collector = TelemetryCollector(TelemetryConfig());

      final successSpan = collector.startSpan('success_query');
      expect(successSpan, isNotNull);
      await Future<void>.delayed(const Duration(milliseconds: 2));
      collector.endSpan(successSpan, true);

      final failureSpan = collector.startSpan('failure_query');
      expect(failureSpan, isNotNull);
      await Future<void>.delayed(const Duration(milliseconds: 2));
      collector.endSpan(failureSpan, false);

      expect(collector.totalQueries, equals(2));
      expect(collector.successfulQueries, equals(1));
      expect(collector.failedQueries, equals(1));
      expect(collector.totalQueryTimeMs, greaterThanOrEqualTo(0));
    });

    test('sanitizeQuery redacts quoted literals', () {
      final sanitized = TelemetryCollector.sanitizeQuery(
        "SELECT * FROM users WHERE name='alice' AND city='NYC'",
      );
      expect(sanitized, equals("SELECT * FROM users WHERE name='?' AND city='?'"));
    });
  });
}
