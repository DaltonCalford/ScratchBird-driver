// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

enum CircuitState { closed, open, halfOpen }

class CircuitBreakerConfig {
  int failureThreshold;
  int recoveryTimeoutMs;
  int successThreshold;
  int halfOpenMaxRequests;

  CircuitBreakerConfig({
    this.failureThreshold = 5,
    this.recoveryTimeoutMs = 30000,
    this.successThreshold = 3,
    this.halfOpenMaxRequests = 10,
  });
}

class CircuitBreaker {
  final CircuitBreakerConfig config;
  CircuitState _state = CircuitState.closed;
  int _failureCount = 0;
  int _successCount = 0;
  int _halfOpenRequests = 0;
  int? _lastFailureAt;

  CircuitBreaker([CircuitBreakerConfig? config]) : config = config ?? CircuitBreakerConfig();

  CircuitState get state => _state;

  bool allowRequest() {
    if (_state == CircuitState.closed) {
      return true;
    }
    if (_state == CircuitState.open) {
      if (_lastFailureAt != null && (DateTime.now().millisecondsSinceEpoch - _lastFailureAt!) >= config.recoveryTimeoutMs) {
        _transitionToHalfOpen();
        return _allowHalfOpenRequest();
      }
      return false;
    }
    return _allowHalfOpenRequest();
  }

  void recordSuccess() {
    if (_state == CircuitState.closed) {
      _failureCount = 0;
      return;
    }
    if (_state == CircuitState.halfOpen) {
      _halfOpenRequests = (_halfOpenRequests - 1).clamp(0, config.halfOpenMaxRequests);
      _successCount += 1;
      if (_successCount >= config.successThreshold) {
        _transitionToClosed();
      }
    }
  }

  void recordFailure() {
    if (_state == CircuitState.closed) {
      _failureCount += 1;
      if (_failureCount >= config.failureThreshold) {
        _transitionToOpen();
      }
      return;
    }
    if (_state == CircuitState.halfOpen) {
      _halfOpenRequests = (_halfOpenRequests - 1).clamp(0, config.halfOpenMaxRequests);
      _transitionToOpen();
      return;
    }
    if (_state == CircuitState.open) {
      _lastFailureAt = DateTime.now().millisecondsSinceEpoch;
    }
  }

  void reset() {
    _transitionToClosed();
  }

  bool _allowHalfOpenRequest() {
    if (_halfOpenRequests < config.halfOpenMaxRequests) {
      _halfOpenRequests += 1;
      return true;
    }
    return false;
  }

  void _transitionToHalfOpen() {
    _state = CircuitState.halfOpen;
    _failureCount = 0;
    _successCount = 0;
    _halfOpenRequests = 0;
  }

  void _transitionToOpen() {
    _state = CircuitState.open;
    _lastFailureAt = DateTime.now().millisecondsSinceEpoch;
  }

  void _transitionToClosed() {
    _state = CircuitState.closed;
    _failureCount = 0;
    _successCount = 0;
    _halfOpenRequests = 0;
    _lastFailureAt = null;
  }
}
