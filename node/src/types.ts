export interface ClientConfig {
  host?: string;
  port?: number;
  user?: string;
  password?: string;
  database?: string;
  ssl?: boolean | Record<string, any>;
  sslmode?: string;
  sslrootcert?: string;
  sslcert?: string;
  sslkey?: string;
  connectTimeoutMs?: number;
  socketTimeoutMs?: number;
  applicationName?: string;
  binaryTransfer?: boolean;
  compression?: "zstd" | "off";
}

export interface FieldDef {
  name: string;
  dataType: string;
  format: "text" | "binary";
  nullable: boolean;
}

export interface QueryResult<T = any> {
  rows: T[];
  rowCount: number;
  fields: FieldDef[];
  command: string;
}

export enum WireType {
  NULL_TYPE = 0x00,
  BOOLEAN = 0x01,
  INT16 = 0x02,
  INT32 = 0x03,
  INT64 = 0x04,
  FLOAT32 = 0x05,
  FLOAT64 = 0x06,
  DECIMAL = 0x07,
  VARCHAR = 0x08,
  CHAR = 0x09,
  BYTEA = 0x0a,
  DATE = 0x0b,
  TIME = 0x0c,
  TIMESTAMP = 0x0d,
  TIMESTAMPTZ = 0x0e,
  INTERVAL = 0x0f,
  UUID = 0x10,
  JSON = 0x11,
  JSONB = 0x12,
  ARRAY = 0x13,
  COMPOSITE = 0x14,
  GEOMETRY = 0x15,
  VECTOR = 0x16,
  MONEY = 0x17,
  XML = 0x18,
  INET = 0x19,
  CIDR = 0x1a,
  MACADDR = 0x1b,
  TSVECTOR = 0x1c,
  TSQUERY = 0x1d,
  RANGE = 0x1e,
  UNKNOWN = 0xff,
}

export function wireTypeToString(type: number): string {
  switch (type) {
    case WireType.BOOLEAN:
      return "boolean";
    case WireType.INT16:
      return "int16";
    case WireType.INT32:
      return "int32";
    case WireType.INT64:
      return "int64";
    case WireType.FLOAT32:
      return "float32";
    case WireType.FLOAT64:
      return "float64";
    case WireType.DECIMAL:
      return "decimal";
    case WireType.VARCHAR:
      return "varchar";
    case WireType.CHAR:
      return "char";
    case WireType.BYTEA:
      return "bytea";
    case WireType.DATE:
      return "date";
    case WireType.TIME:
      return "time";
    case WireType.TIMESTAMP:
      return "timestamp";
    case WireType.TIMESTAMPTZ:
      return "timestamptz";
    case WireType.INTERVAL:
      return "interval";
    case WireType.UUID:
      return "uuid";
    case WireType.JSON:
      return "json";
    case WireType.JSONB:
      return "jsonb";
    case WireType.ARRAY:
      return "array";
    case WireType.COMPOSITE:
      return "composite";
    case WireType.GEOMETRY:
      return "geometry";
    case WireType.VECTOR:
      return "vector";
    case WireType.MONEY:
      return "money";
    case WireType.XML:
      return "xml";
    case WireType.INET:
      return "inet";
    case WireType.CIDR:
      return "cidr";
    case WireType.MACADDR:
      return "macaddr";
    case WireType.TSVECTOR:
      return "tsvector";
    case WireType.TSQUERY:
      return "tsquery";
    case WireType.RANGE:
      return "range";
    default:
      return "unknown";
  }
}

export function decodeValue(type: number, data: Buffer | null): any {
  if (data === null) {
    return null;
  }
  switch (type) {
    case WireType.BOOLEAN:
      return data[0] === 1;
    case WireType.INT16:
      return data.readInt16LE(0);
    case WireType.INT32:
      return data.readInt32LE(0);
    case WireType.INT64:
      return data.readBigInt64LE(0);
    case WireType.FLOAT32:
      return data.readFloatLE(0);
    case WireType.FLOAT64:
      return data.readDoubleLE(0);
    case WireType.DECIMAL:
      return data.toString("utf8");
    case WireType.VARCHAR:
    case WireType.CHAR:
    case WireType.JSON:
    case WireType.JSONB:
    case WireType.XML:
    case WireType.TSVECTOR:
    case WireType.TSQUERY:
      return data.toString("utf8");
    case WireType.BYTEA:
      return Buffer.from(data);
    case WireType.DATE: {
      const days = data.readInt32LE(0);
      const base = Date.UTC(2000, 0, 1);
      const millis = base + days * 86400000;
      return new Date(millis).toISOString().slice(0, 10);
    }
    case WireType.TIME: {
      const micros = Number(data.readBigInt64LE(0));
      const totalSeconds = Math.floor(micros / 1_000_000);
      const micro = micros % 1_000_000;
      const hours = Math.floor(totalSeconds / 3600) % 24;
      const minutes = Math.floor((totalSeconds % 3600) / 60);
      const seconds = totalSeconds % 60;
      const microStr = micro ? "." + String(micro).padStart(6, "0") : "";
      return `${String(hours).padStart(2, "0")}:${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}${microStr}`;
    }
    case WireType.TIMESTAMP: {
      const micros = Number(data.readBigInt64LE(0));
      return new Date(micros / 1000);
    }
    case WireType.TIMESTAMPTZ: {
      const micros = Number(data.readBigInt64LE(0));
      return new Date(micros / 1000);
    }
    case WireType.INTERVAL: {
      const months = data.readInt32LE(0);
      const days = data.readInt32LE(4);
      const micros = Number(data.readBigInt64LE(8));
      return { months, days, micros };
    }
    case WireType.UUID:
      return bytesToUuid(data);
    case WireType.MONEY: {
      const cents = data.readBigInt64LE(0);
      return Number(cents) / 100;
    }
    case WireType.INET:
    case WireType.CIDR:
      return data.toString("utf8");
    case WireType.ARRAY:
      return parseArrayLiteral(data.toString("utf8"));
    case WireType.VECTOR:
      return parseVectorLiteral(data.toString("utf8"));
    default:
      return data;
  }
}

function bytesToUuid(buf: Buffer): string {
  const hex = buf.toString("hex");
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}

function parseArrayLiteral(text: string): any[] {
  let trimmed = text.trim();
  if (trimmed === "{}" || trimmed === "") {
    return [];
  }
  if (trimmed.startsWith("{") && trimmed.endsWith("}")) {
    trimmed = trimmed.slice(1, -1);
  }
  return splitArrayItems(trimmed);
}

function splitArrayItems(text: string): any[] {
  const items: any[] = [];
  let depth = 0;
  let buf = "";
  for (let i = 0; i < text.length; i++) {
    const ch = text[i];
    if (ch === "{") {
      depth++;
      buf += ch;
    } else if (ch === "}") {
      depth = Math.max(0, depth - 1);
      buf += ch;
    } else if (ch === "," && depth === 0) {
      items.push(parseArrayItem(buf));
      buf = "";
    } else {
      buf += ch;
    }
  }
  if (buf.length || text.length) {
    items.push(parseArrayItem(buf));
  }
  return items;
}

function parseArrayItem(raw: string): any {
  const token = raw.trim();
  if (token === "") {
    return "";
  }
  if (token.toUpperCase() === "NULL") {
    return null;
  }
  if (token.startsWith("{") && token.endsWith("}")) {
    return parseArrayLiteral(token);
  }
  if (token.startsWith("[") && token.endsWith("]")) {
    return parseVectorLiteral(token);
  }
  if (token === "true" || token === "false") {
    return token === "true";
  }
  const num = Number(token);
  if (!Number.isNaN(num)) {
    return num;
  }
  return token;
}

function parseVectorLiteral(text: string): number[] {
  let trimmed = text.trim();
  if (trimmed.startsWith("[") && trimmed.endsWith("]")) {
    trimmed = trimmed.slice(1, -1);
  }
  if (!trimmed) {
    return [];
  }
  return trimmed.split(",").map((part) => Number(part.trim())).filter((val) => !Number.isNaN(val));
}
