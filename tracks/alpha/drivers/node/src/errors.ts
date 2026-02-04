// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
export class ScratchbirdError extends Error {
  code?: string;
  detail?: string;
  hint?: string;
  constructor(message: string, code?: string, detail?: string, hint?: string) {
    super(message);
    this.name = this.constructor.name;
    this.code = code;
    this.detail = detail;
    this.hint = hint;
  }
}

export class ScratchbirdWarning extends ScratchbirdError {}
export class ScratchbirdNoDataError extends ScratchbirdError {}
export class ScratchbirdConnectionError extends ScratchbirdError {}
export class ScratchbirdNotSupportedError extends ScratchbirdError {}
export class ScratchbirdDataError extends ScratchbirdError {}
export class ScratchbirdIntegrityError extends ScratchbirdError {}
export class ScratchbirdAuthError extends ScratchbirdError {}
export class ScratchbirdTransactionError extends ScratchbirdError {}
export class ScratchbirdSyntaxError extends ScratchbirdError {}
export class ScratchbirdResourceError extends ScratchbirdError {}
export class ScratchbirdLimitError extends ScratchbirdError {}
export class ScratchbirdOperatorInterventionError extends ScratchbirdError {}
export class ScratchbirdSystemError extends ScratchbirdError {}
export class ScratchbirdInternalError extends ScratchbirdError {}

export function mapSqlState(code?: string): new (...args: any[]) => ScratchbirdError {
  if (!code || code.length < 2) {
    return ScratchbirdError;
  }
  if (code.length === 5) {
    switch (code) {
      case "01000":
        return ScratchbirdWarning;
      case "02000":
        return ScratchbirdNoDataError;
      case "08001":
      case "08003":
      case "08004":
      case "08006":
      case "08P01":
        return ScratchbirdConnectionError;
      case "0A000":
        return ScratchbirdNotSupportedError;
      case "22001":
      case "22003":
      case "22007":
      case "22012":
      case "22023":
      case "22P02":
      case "22P03":
        return ScratchbirdDataError;
      case "23000":
      case "23502":
      case "23503":
      case "23505":
      case "23514":
        return ScratchbirdIntegrityError;
      case "28000":
      case "28P01":
        return ScratchbirdAuthError;
      case "40001":
      case "40P01":
        return ScratchbirdTransactionError;
      case "42501":
      case "42601":
      case "42703":
      case "42704":
      case "42710":
      case "42883":
      case "42P01":
      case "42P07":
        return ScratchbirdSyntaxError;
      case "53P00":
      case "53100":
      case "53200":
      case "53300":
        return ScratchbirdResourceError;
      case "54000":
        return ScratchbirdLimitError;
      case "57014":
      case "57P01":
      case "57P03":
        return ScratchbirdOperatorInterventionError;
      case "58000":
        return ScratchbirdSystemError;
      case "XX000":
        return ScratchbirdInternalError;
    }
  }
  return ScratchbirdError;
}
