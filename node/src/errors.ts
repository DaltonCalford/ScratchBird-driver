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
  const cls = code.slice(0, 2);
  switch (cls) {
    case "01":
      return ScratchbirdWarning;
    case "02":
      return ScratchbirdNoDataError;
    case "08":
      return ScratchbirdConnectionError;
    case "0A":
      return ScratchbirdNotSupportedError;
    case "22":
      return ScratchbirdDataError;
    case "23":
      return ScratchbirdIntegrityError;
    case "28":
      return ScratchbirdAuthError;
    case "40":
      return ScratchbirdTransactionError;
    case "42":
      return ScratchbirdSyntaxError;
    case "53":
      return ScratchbirdResourceError;
    case "54":
      return ScratchbirdLimitError;
    case "57":
      return ScratchbirdOperatorInterventionError;
    case "58":
      return ScratchbirdSystemError;
    case "XX":
      return ScratchbirdInternalError;
    default:
      return ScratchbirdError;
  }
}
