import { Buffer } from "node:buffer";

export const PROTOCOL_MAGIC = 0x42444253;
export const PROTOCOL_VERSION_MAJOR = 1;
export const PROTOCOL_VERSION_MINOR = 0;
export const PROTOCOL_VERSION = (PROTOCOL_VERSION_MAJOR << 8) | PROTOCOL_VERSION_MINOR;
export const MAX_MESSAGE_SIZE = 16 * 1024 * 1024;

export enum MessageType {
  CONNECT_REQUEST = 0x01,
  CONNECT_RESPONSE = 0x02,
  DISCONNECT = 0x03,
  AUTH_REQUEST = 0x10,
  AUTH_RESPONSE = 0x11,
  QUERY = 0x20,
  QUERY_RESULT = 0x21,
  QUERY_ERROR = 0x22,
  QUERY_CANCEL = 0x23,
  PREPARE = 0x30,
  PREPARE_RESPONSE = 0x31,
  EXECUTE = 0x32,
  CLOSE_STATEMENT = 0x33,
  DESCRIBE = 0x34,
  DESCRIBE_RESPONSE = 0x35,
  BEGIN_TRANSACTION = 0x40,
  COMMIT = 0x41,
  ROLLBACK = 0x42,
  SAVEPOINT = 0x43,
  RELEASE_SAVEPOINT = 0x44,
  ROLLBACK_TO = 0x45,
  TRANSACTION_STATUS = 0x46,
  ROW_DESCRIPTION = 0x50,
  ROW_DATA = 0x51,
  END_OF_RESULTS = 0x52,
  COMMAND_COMPLETE = 0x53,
  COPY_DATA = 0x70,
  COPY_DONE = 0x71,
  COPY_FAIL = 0x72,
  COPY_IN_RESPONSE = 0x73,
  COPY_OUT_RESPONSE = 0x74,
  COPY_BOTH_RESPONSE = 0x75,
  STREAM_CONTROL = 0x76,
  STREAM_READY = 0x77,
  STREAM_DATA = 0x78,
  STREAM_END = 0x79,
}

export enum AuthMethod {
  PASSWORD = 0,
  MD5 = 1,
  SCRAM_SHA_256 = 2,
  SCRAM_SHA_512 = 3,
}

export enum AuthStatus {
  OK = 0,
  ERROR = 1,
  CONTINUE = 2,
}

export interface ColumnInfo {
  name: string;
  wireType: number;
  typeModifier: number;
  formatCode: number;
}

export interface ColumnValue {
  data: Buffer | null;
}

export function encodeMessage(type: number, payload: Buffer, flags = 0): Buffer {
  const header = Buffer.alloc(12);
  header.writeUInt32LE(PROTOCOL_MAGIC, 0);
  header.writeUInt16LE(PROTOCOL_VERSION, 4);
  header.writeUInt8(type, 6);
  header.writeUInt8(flags, 7);
  header.writeUInt32LE(payload.length, 8);
  return Buffer.concat([header, payload]);
}

export function decodeHeader(data: Buffer): { version: number; type: number; flags: number; length: number } {
  if (data.length !== 12) {
    throw new Error("Invalid header length");
  }
  const magic = data.readUInt32LE(0);
  if (magic !== PROTOCOL_MAGIC) {
    throw new Error("Invalid protocol magic");
  }
  const version = data.readUInt16LE(4);
  const type = data.readUInt8(6);
  const flags = data.readUInt8(7);
  const length = data.readUInt32LE(8);
  if (length > MAX_MESSAGE_SIZE) {
    throw new Error("Payload too large");
  }
  return { version, type, flags, length };
}

export function buildConnectRequest(database: string, clientName: string, pid: number): Buffer {
  const payload = Buffer.alloc(2 + 2 + 4 + 256 + 64 + 32);
  let offset = 0;
  payload.writeUInt16LE(PROTOCOL_VERSION, offset);
  offset += 2;
  payload.writeUInt16LE(0, offset);
  offset += 2;
  payload.writeUInt32LE(pid, offset);
  offset += 4;
  writeNullTerminated(payload, database, offset, 256);
  offset += 256;
  writeNullTerminated(payload, clientName, offset, 64);
  offset += 64;
  writeNullTerminated(payload, "1.0.0", offset, 32);
  return encodeMessage(MessageType.CONNECT_REQUEST, payload);
}

export function parseConnectResponse(payload: Buffer): {
  success: boolean;
  sessionId: Buffer;
  version: number;
  serverName: string;
  serverVersion: string;
  errorMessage: string;
} {
  if (payload.length < 1 + 2 + 2 + 16 + 64 + 32) {
    throw new Error("Connect response truncated");
  }
  let offset = 0;
  const status = payload.readUInt8(offset);
  offset += 1;
  const version = payload.readUInt16LE(offset);
  offset += 2;
  offset += 2;
  const sessionId = payload.subarray(offset, offset + 16);
  offset += 16;
  const serverName = readNullTerminated(payload.subarray(offset, offset + 64));
  offset += 64;
  const serverVersion = readNullTerminated(payload.subarray(offset, offset + 32));
  offset += 32;
  let errorMessage = "";
  if (status !== 0 && offset + 2 <= payload.length) {
    const msgLen = payload.readUInt16LE(offset);
    offset += 2;
    errorMessage = payload.subarray(offset, offset + msgLen).toString("utf8");
  }
  return {
    success: status === 0,
    sessionId,
    version,
    serverName,
    serverVersion,
    errorMessage,
  };
}

export function buildAuthRequest(sessionId: Buffer, username: string, method: number, payload: Buffer): Buffer {
  if (sessionId.length !== 16) {
    throw new Error("sessionId must be 16 bytes");
  }
  const header = Buffer.alloc(16 + 64 + 1 + 2 + payload.length);
  sessionId.copy(header, 0);
  writeNullTerminated(header, username, 16, 64);
  header.writeUInt8(method, 16 + 64);
  header.writeUInt16LE(payload.length, 16 + 64 + 1);
  payload.copy(header, 16 + 64 + 1 + 2);
  return encodeMessage(MessageType.AUTH_REQUEST, header);
}

export function parseAuthResponse(payload: Buffer): {
  status: number;
  userId: number;
  errorMessage: string;
  extra: Buffer;
} {
  if (payload.length < 1 + 4 + 256) {
    throw new Error("Auth response truncated");
  }
  const status = payload.readUInt8(0);
  const userId = payload.readUInt32LE(1);
  const errorMessage = readNullTerminated(payload.subarray(5, 5 + 256));
  const extra = payload.subarray(5 + 256);
  return { status, userId, errorMessage, extra };
}

export function buildQuery(sessionId: Buffer, sql: string, flags = 0): Buffer {
  if (sessionId.length !== 16) {
    throw new Error("sessionId must be 16 bytes");
  }
  const sqlBytes = Buffer.from(sql, "utf8");
  const payload = Buffer.alloc(16 + 4 + 1 + sqlBytes.length);
  sessionId.copy(payload, 0);
  payload.writeUInt32LE(sqlBytes.length, 16);
  payload.writeUInt8(flags, 20);
  sqlBytes.copy(payload, 21);
  return encodeMessage(MessageType.QUERY, payload);
}

export function parseRowDescription(payload: Buffer): ColumnInfo[] {
  if (payload.length < 2) {
    throw new Error("Row description truncated");
  }
  let offset = 0;
  const count = payload.readUInt16LE(offset);
  offset += 2;
  const columns: ColumnInfo[] = [];
  for (let i = 0; i < count; i++) {
    if (offset + 2 > payload.length) {
      throw new Error("Row description truncated");
    }
    const nameLen = payload.readUInt16LE(offset);
    offset += 2;
    const name = payload.subarray(offset, offset + nameLen).toString("utf8");
    offset += nameLen;
    const wireType = payload.readUInt8(offset);
    offset += 1;
    const typeModifier = payload.readUInt32LE(offset);
    offset += 4;
    const formatCode = payload.readUInt16LE(offset);
    offset += 2;
    columns.push({ name, wireType, typeModifier, formatCode });
  }
  return columns;
}

export function parseRowData(payload: Buffer): ColumnValue[] {
  if (payload.length < 2) {
    throw new Error("Row data truncated");
  }
  let offset = 0;
  const count = payload.readUInt16LE(offset);
  offset += 2;
  const values: ColumnValue[] = [];
  for (let i = 0; i < count; i++) {
    if (offset + 4 > payload.length) {
      throw new Error("Row data truncated");
    }
    const length = payload.readInt32LE(offset);
    offset += 4;
    if (length < 0) {
      values.push({ data: null });
      continue;
    }
    if (offset + length > payload.length) {
      throw new Error("Row data truncated");
    }
    const data = payload.subarray(offset, offset + length);
    offset += length;
    values.push({ data });
  }
  return values;
}

export function parseCommandComplete(payload: Buffer): { tag: string; rowsAffected: number } {
  if (payload.length < 64 + 8) {
    throw new Error("Command complete truncated");
  }
  const tag = readNullTerminated(payload.subarray(0, 64));
  const rowsAffected = Number(payload.readBigInt64LE(64));
  return { tag, rowsAffected };
}

export function parseQueryResult(payload: Buffer): { status: number; columnCount: number; rowCount: number } {
  if (payload.length < 1 + 4 + 8) {
    throw new Error("Query result truncated");
  }
  const status = payload.readUInt8(0);
  const columnCount = payload.readUInt32LE(1);
  const rowCount = Number(payload.readBigInt64LE(5));
  return { status, columnCount, rowCount };
}

export function parseQueryError(payload: Buffer): {
  errorCode: number;
  sqlstate: string;
  message: string;
  detail: string;
  hint: string;
} {
  if (payload.length < 4 + 6 + 2 + 2 + 2) {
    throw new Error("Query error truncated");
  }
  let offset = 0;
  const errorCode = payload.readUInt32LE(offset);
  offset += 4;
  const sqlstate = readNullTerminated(payload.subarray(offset, offset + 6));
  offset += 6;
  const messageLen = payload.readUInt16LE(offset);
  offset += 2;
  const detailLen = payload.readUInt16LE(offset);
  offset += 2;
  const hintLen = payload.readUInt16LE(offset);
  offset += 2;
  const message = payload.subarray(offset, offset + messageLen).toString("utf8");
  offset += messageLen;
  const detail = payload.subarray(offset, offset + detailLen).toString("utf8");
  offset += detailLen;
  const hint = payload.subarray(offset, offset + hintLen).toString("utf8");
  return { errorCode, sqlstate, message, detail, hint };
}

export function buildCommit(sessionId: Buffer): Buffer {
  return encodeMessage(MessageType.COMMIT, sessionId);
}

export function buildRollback(sessionId: Buffer): Buffer {
  return encodeMessage(MessageType.ROLLBACK, sessionId);
}

export function buildBegin(sessionId: Buffer, isolationLevel = 0, readOnly = false): Buffer {
  const payload = Buffer.alloc(16 + 1 + 1);
  sessionId.copy(payload, 0);
  payload.writeUInt8(isolationLevel, 16);
  payload.writeUInt8(readOnly ? 1 : 0, 17);
  return encodeMessage(MessageType.BEGIN_TRANSACTION, payload);
}

export function buildDisconnect(sessionId: Buffer): Buffer {
  return encodeMessage(MessageType.DISCONNECT, sessionId);
}

function writeNullTerminated(buf: Buffer, value: string, offset: number, maxLen: number): void {
  const encoded = Buffer.from(value ?? "", "utf8");
  const len = Math.min(encoded.length, maxLen - 1);
  encoded.copy(buf, offset, 0, len);
  buf.fill(0, offset + len, offset + maxLen);
}

function readNullTerminated(buf: Buffer): string {
  const idx = buf.indexOf(0);
  const slice = idx >= 0 ? buf.subarray(0, idx) : buf;
  return slice.toString("utf8");
}
