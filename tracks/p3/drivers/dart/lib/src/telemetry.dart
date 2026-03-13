// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

import 'dart:math';

class TelemetryConfig {
  bool enableTracing = true;
  bool enableMetrics = true;
  bool enableSlowQueryLog = true;
  int slowQueryThresholdMs = 1000;
  bool sanitizeQueries = true;
  double sampleRate = 1.0;
}

class SpanContext {
  final String traceId;
  final String spanId;
  final String? parentSpanId;
  final String spanName;
  final int startTimeMs = DateTime.now().millisecondsSinceEpoch;
  final Map<String, String> attributes = {};

  SpanContext(this.spanName, [SpanContext? parent])
      : traceId = parent?.traceId ?? _randomHex(32),
        spanId = _randomHex(16),
        parentSpanId = parent?.spanId;

  SpanContext withAttribute(String key, String value) {
    attributes[key] = value;
    return this;
  }

  int elapsedMs() => DateTime.now().millisecondsSinceEpoch - startTimeMs;

  static String _randomHex(int length) {
    final rand = Random.secure();
    const chars = '0123456789abcdef';
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)])
        .join();
  }
}

class TelemetryCollector {
  final TelemetryConfig config;
  final List<SpanContext> _spans = [];
  int totalQueries = 0;
  int successfulQueries = 0;
  int failedQueries = 0;
  int totalQueryTimeMs = 0;
  final List<Map<String, dynamic>> _slowQueries = [];

  TelemetryCollector([TelemetryConfig? config])
      : config = config ?? TelemetryConfig();

  SpanContext? startSpan(String name) {
    if (!config.enableTracing) return null;
    if (Random().nextDouble() > config.sampleRate) return null;
    final span = SpanContext(name);
    _spans.add(span);
    if (_spans.length > 1000) {
      _spans.removeAt(0);
    }
    return span;
  }

  void endSpan(SpanContext? span, bool success) {
    if (span == null || !config.enableTracing) return;
    final durationMs = span.elapsedMs();
    _recordQueryMetrics(durationMs, success);
    if (config.enableSlowQueryLog && durationMs > config.slowQueryThresholdMs) {
      _slowQueries.add({
        'traceId': span.traceId,
        'spanName': span.spanName,
        'durationMs': durationMs,
        'timestamp': DateTime.now().toIso8601String(),
        'attributes': span.attributes,
      });
      if (_slowQueries.length > 100) {
        _slowQueries.removeAt(0);
      }
    }
  }

  int get slowQueryCount => _slowQueries.length;

  List<Map<String, dynamic>> get slowQueries =>
      List<Map<String, dynamic>>.unmodifiable(
        _slowQueries.map(
          (entry) => Map<String, dynamic>.unmodifiable(
              Map<String, dynamic>.from(entry)),
        ),
      );

  static String sanitizeQuery(String sql) {
    return sql.replaceAll(RegExp(r"'[^']*'"), "'?'");
  }

  void _recordQueryMetrics(int durationMs, bool success) {
    if (!config.enableMetrics) return;
    totalQueries += 1;
    if (success) {
      successfulQueries += 1;
    } else {
      failedQueries += 1;
    }
    totalQueryTimeMs += durationMs;
  }
}
