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

class ScratchBirdOperationalException extends ScratchBirdExecutionException {
  const ScratchBirdOperationalException(
    super.message, {
    super.sqlState,
    super.code,
  });
}

class ScratchBirdDataException extends ScratchBirdExecutionException {
  const ScratchBirdDataException(
    super.message, {
    super.sqlState,
    super.code,
  });
}

class ScratchBirdIntegrityException extends ScratchBirdExecutionException {
  const ScratchBirdIntegrityException(
    super.message, {
    super.sqlState,
    super.code,
  });
}

class ScratchBirdProgrammingException extends ScratchBirdExecutionException {
  const ScratchBirdProgrammingException(
    super.message, {
    super.sqlState,
    super.code,
  });
}

class ScratchBirdNotSupportedException extends ScratchBirdExecutionException {
  const ScratchBirdNotSupportedException(
    super.message, {
    super.sqlState,
    super.code,
  });
}

class ScratchBirdInternalException extends ScratchBirdExecutionException {
  const ScratchBirdInternalException(
    super.message, {
    super.sqlState,
    super.code,
  });
}

ScratchBirdExecutionException mapSqlStateExecutionException(
  String message, {
  String? sqlState,
  int? code,
}) {
  final normalized = (sqlState ?? '').trim().toUpperCase();
  if (normalized.isEmpty) {
    return ScratchBirdExecutionException(message, code: code);
  }

  final sqlStateOut = normalized;
  if (normalized.length >= 2) {
    final cls = normalized.substring(0, 2);
    switch (cls) {
      case '08':
        return ScratchBirdOperationalException(
          message,
          sqlState: sqlStateOut,
          code: code,
        );
      case '22':
        return ScratchBirdDataException(
          message,
          sqlState: sqlStateOut,
          code: code,
        );
      case '23':
        return ScratchBirdIntegrityException(
          message,
          sqlState: sqlStateOut,
          code: code,
        );
      case '42':
        return ScratchBirdProgrammingException(
          message,
          sqlState: sqlStateOut,
          code: code,
        );
      case '0A':
        return ScratchBirdNotSupportedException(
          message,
          sqlState: sqlStateOut,
          code: code,
        );
      case 'XX':
        return ScratchBirdInternalException(
          message,
          sqlState: sqlStateOut,
          code: code,
        );
    }
  }

  return ScratchBirdExecutionException(
    message,
    sqlState: sqlStateOut,
    code: code,
  );
}
