// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

import 'dart:async';

class LeakDetectionConfig {
  int thresholdMs;
  bool captureStackTrace;
  int checkIntervalMs;

  LeakDetectionConfig({
    this.thresholdMs = 30000,
    this.captureStackTrace = false,
    this.checkIntervalMs = 10000,
  });
}

class CheckoutInfo {
  final int checkoutTime = DateTime.now().millisecondsSinceEpoch;
  final String? stackTrace;
  final Map<String, String> metadata;

  CheckoutInfo(this.metadata, {required bool captureStackTrace})
      : stackTrace = captureStackTrace ? StackTrace.current.toString() : null;

  int heldDurationMs() => DateTime.now().millisecondsSinceEpoch - checkoutTime;
}

class LeakDetectionGuard {
  final LeakDetector _detector;
  final String _connectionId;
  bool _released = false;

  LeakDetectionGuard(this._detector, this._connectionId);

  void release() {
    if (_released) return;
    _released = true;
    _detector.checkin(_connectionId);
  }
}

class LeakDetector {
  final LeakDetectionConfig config;
  final Map<String, CheckoutInfo> _checkouts = {};
  Timer? _timer;

  LeakDetector([LeakDetectionConfig? config]) : config = config ?? LeakDetectionConfig();

  void start() {
    if (_timer != null) return;
    _timer = Timer.periodic(Duration(milliseconds: config.checkIntervalMs), (_) => _checkLeaks());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  LeakDetectionGuard checkout(String connectionId, {Map<String, String> metadata = const {}}) {
    _checkouts[connectionId] = CheckoutInfo(Map<String, String>.from(metadata), captureStackTrace: config.captureStackTrace);
    return LeakDetectionGuard(this, connectionId);
  }

  void checkin(String connectionId) {
    _checkouts.remove(connectionId);
  }

  void _checkLeaks() {
    for (final entry in _checkouts.entries) {
      if (entry.value.heldDurationMs() > config.thresholdMs) {
        // ignore: avoid_print
        print("POSSIBLE CONNECTION LEAK: conn=${entry.key} held=${entry.value.heldDurationMs()}ms");
      }
    }
  }
}
