// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

class ScratchBirdException implements Exception {
  final String message;
  final String? sqlState;
  final int? code;

  const ScratchBirdException(
    this.message, {
    this.sqlState,
    this.code,
  });

  @override
  String toString() {
    final parts = <String>[message];
    if (sqlState != null && sqlState!.isNotEmpty) {
      parts.add('sqlState=$sqlState');
    }
    if (code != null) {
      parts.add('code=$code');
    }
    return 'ScratchBirdException(${parts.join(', ')})';
  }
}

class ScratchBirdConnectionException extends ScratchBirdException {
  const ScratchBirdConnectionException(
    super.message, {
    super.sqlState,
    super.code,
  });
}

class ScratchBirdProtocolException extends ScratchBirdException {
  const ScratchBirdProtocolException(
    super.message, {
    super.sqlState,
    super.code,
  });
}

class ScratchBirdAuthException extends ScratchBirdException {
  const ScratchBirdAuthException(
    super.message, {
    super.sqlState,
    super.code,
  });
}

class ScratchBirdTransactionException extends ScratchBirdException {
  const ScratchBirdTransactionException(
    super.message, {
    super.sqlState,
    super.code,
  });
}

class ScratchBirdExecutionException extends ScratchBirdException {
  const ScratchBirdExecutionException(
    super.message, {
    super.sqlState,
    super.code,
  });
}
