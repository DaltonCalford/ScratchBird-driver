import net from "node:net";
import tls from "node:tls";
import fs from "node:fs";
import {
  AuthMethod,
  MessageType,
  MSG_FLAG_URGENT,
  FEATURE_COMPRESSION,
  FEATURE_STREAMING,
  HEADER_SIZE,
  buildStartupPayload,
  buildQueryPayload,
  buildParsePayload,
  buildBindPayload,
  buildExecutePayload,
  buildCancelPayload,
  encodeMessage,
  decodeHeader,
  parseAuthRequest,
  parseAuthContinue,
  parseAuthOk,
  parseReady,
  parseParameterStatus,
  parseRowDescription,
  parseDataRow,
  parseCommandComplete,
  parseErrorMessage,
  MessageHeader,
} from "./protocol";
import { ScramExchange } from "./scram";
import { parseDsn } from "./dsn";
import { normalizeQuery } from "./sql";
import {
  ClientConfig,
  FieldDef,
  QueryResult,
  ParamValue,
  FORMAT_BINARY,
  oidToString,
  encodeParam,
  decodeValue,
} from "./types";
import { mapSqlState, ScratchbirdError } from "./errors";

const QUERY_FLAG_BINARY_RESULT = 0x04;
const FORMAT_TEXT = 0;

interface Message {
  header: MessageHeader;
  payload: Buffer;
}

interface QueryOptions {
  signal?: AbortSignal;
  maxRows?: number;
  timeoutMs?: number;
}

class SocketReader {
  private buffer = Buffer.alloc(0);
  private pending: Array<{ len: number; resolve: (buf: Buffer) => void; reject: (err: Error) => void }> = [];
  private closed = false;

  constructor(private socket: net.Socket) {
    socket.on("data", (chunk) => this.onData(chunk));
    socket.on("error", (err) => this.fail(err instanceof Error ? err : new Error(String(err))));
    socket.on("close", () => this.fail(new Error("Connection closed")));
  }

  readExact(len: number): Promise<Buffer> {
    if (this.closed) {
      return Promise.reject(new Error("Connection closed"));
    }
    if (this.buffer.length >= len) {
      const out = this.buffer.subarray(0, len);
      this.buffer = this.buffer.subarray(len);
      return Promise.resolve(out);
    }
    return new Promise((resolve, reject) => {
      this.pending.push({ len, resolve, reject });
    });
  }

  private onData(chunk: Buffer): void {
    this.buffer = this.buffer.length ? Buffer.concat([this.buffer, chunk]) : chunk;
    this.flush();
  }

  private flush(): void {
    while (this.pending.length && this.buffer.length >= this.pending[0].len) {
      const next = this.pending.shift();
      if (!next) break;
      const out = this.buffer.subarray(0, next.len);
      this.buffer = this.buffer.subarray(next.len);
      next.resolve(out);
    }
  }

  private fail(err: Error): void {
    if (this.closed) return;
    this.closed = true;
    while (this.pending.length) {
      const next = this.pending.shift();
      if (next) next.reject(err);
    }
  }
}

class ProtocolConnection {
  private socket?: net.Socket;
  private reader?: SocketReader;
  private attachmentId = Buffer.alloc(16);
  private txnId = 0n;
  private sequence = 0;

  async connect(config: ClientConfig): Promise<void> {
    const host = config.host ?? "localhost";
    const port = config.port ?? 3092;
    const sslMode = resolveSslMode(config);
    if (sslMode === "disable") {
      throw new Error("TLS is required for ScratchBird connections");
    }

    let rawSocket = await connectTcp(host, port, config.connectTimeoutMs ?? 30000);
    rawSocket = await upgradeTls(rawSocket, host, sslMode, config);

    if (config.socketTimeoutMs && config.socketTimeoutMs > 0) {
      rawSocket.setTimeout(config.socketTimeoutMs);
    }

    this.socket = rawSocket;
    this.reader = new SocketReader(rawSocket);
  }

  setAttachment(id: Buffer, txnId: bigint): void {
    this.attachmentId = Buffer.from(id);
    this.txnId = txnId;
  }

  setTxnId(txnId: bigint): void {
    this.txnId = txnId;
  }

  async sendMessage(type: number, payload: Buffer, flags: number, forceZero: boolean): Promise<number> {
    if (!this.socket) throw new Error("Socket not connected");
    const seq = this.sequence++;
    const header: MessageHeader = {
      type,
      flags,
      length: payload.length,
      sequence: seq,
      attachmentId: forceZero ? Buffer.alloc(16) : this.attachmentId,
      txnId: forceZero ? 0n : this.txnId,
    };
    const data = encodeMessage(header, payload);
    await new Promise<void>((resolve, reject) => {
      this.socket!.write(data, (err) => {
        if (err) reject(err);
        else resolve();
      });
    });
    return seq;
  }

  async recv(): Promise<Message> {
    if (!this.reader) throw new Error("Socket not connected");
    const headerBuf = await this.reader.readExact(HEADER_SIZE);
    const header = decodeHeader(headerBuf);
    const payload = header.length ? await this.reader.readExact(header.length) : Buffer.alloc(0);
    return { header, payload };
  }

  close(): void {
    if (this.socket) {
      this.socket.destroy();
    }
  }
}

export class Client {
  private config: ClientConfig;
  private protocol = new ProtocolConnection();
  private connected = false;
  private prepared = new Map<string, string>();
  private parameters: Record<string, string> = {};

  constructor(config?: ClientConfig | string) {
    const parsed = typeof config === "string" ? parseDsn(config) : {};
    this.config = { ...parsed, ...(typeof config === "object" ? config : {}) };
    if (!this.config.host) this.config.host = "localhost";
    if (!this.config.port) this.config.port = 3092;
    if (!this.config.applicationName) this.config.applicationName = "scratchbird_node";
    if (!this.config.sslmode) this.config.sslmode = "require";
    if (this.config.binaryTransfer === undefined) this.config.binaryTransfer = true;
    if (!this.config.compression) this.config.compression = "off";
  }

  async connect(): Promise<void> {
    if (!this.config.user || !this.config.database) {
      throw new Error("user and database are required");
    }
    await this.protocol.connect(this.config);
    await this.handshake();
    await this.applySchema();
    this.connected = true;
  }

  async query<T = any>(text: string, params?: any[] | Record<string, any>, options?: QueryOptions): Promise<QueryResult<T>> {
    this.ensureConnected();
    const normalized = normalizeQuery(text, params);
    return (await this.executeQuery(normalized.sql, normalized.params, options)) as QueryResult<T>;
  }

  async queryStream(text: string, params?: any[] | Record<string, any>, options?: QueryOptions): Promise<AsyncGenerator<any, void, void>> {
    this.ensureConnected();
    const normalized = normalizeQuery(text, params);
    return this.executeQueryStream(normalized.sql, normalized.params, options);
  }

  async prepare(name: string, text: string, _paramTypes?: string[]): Promise<void> {
    if (!name) throw new Error("name is required");
    this.ensureConnected();
    const normalized = normalizeQuery(text);
    await this.protocol.sendMessage(MessageType.PARSE, buildParsePayload(name, normalized.sql, []), 0, false);
    await this.protocol.sendMessage(MessageType.SYNC, Buffer.alloc(0), 0, false);
    await this.drainUntilReady();
    this.prepared.set(name, normalized.sql);
  }

  async execute<T = any>(name: string, params?: any[] | Record<string, any>, options?: QueryOptions): Promise<QueryResult<T>> {
    this.ensureConnected();
    const sql = this.prepared.get(name);
    if (!sql) throw new Error(`Unknown prepared statement: ${name}`);
    const normalized = normalizeQuery(sql, params);
    return (await this.executePrepared(name, normalized.params, options)) as QueryResult<T>;
  }

  async begin(): Promise<void> {
    this.ensureConnected();
  }

  async commit(): Promise<void> {
    this.ensureConnected();
  }

  async rollback(): Promise<void> {
    this.ensureConnected();
  }

  async end(): Promise<void> {
    if (!this.connected) {
      this.protocol.close();
      return;
    }
    this.protocol.close();
    this.connected = false;
  }

  private ensureConnected(): void {
    if (!this.connected) {
      throw new Error("Client is not connected");
    }
  }

  private requestedFeatures(): bigint {
    let features = 0n;
    if (this.config.compression === "zstd") {
      features |= FEATURE_COMPRESSION;
    }
    if (this.config.binaryTransfer) {
      features |= FEATURE_STREAMING;
    }
    return features;
  }

  private async handshake(): Promise<void> {
    const params: Record<string, string> = {
      database: this.config.database ?? "",
      user: this.config.user ?? "",
    };
    if (this.config.applicationName) {
      params.application_name = this.config.applicationName;
    }
    const startup = buildStartupPayload(this.requestedFeatures(), params);
    await this.protocol.sendMessage(MessageType.STARTUP, startup, 0, true);

    let scram: ScramExchange | null = null;

    while (true) {
      const msg = await this.protocol.recv();
      switch (msg.header.type) {
        case MessageType.NEGOTIATE_VERSION:
          continue;
        case MessageType.AUTH_REQUEST: {
          const { method, data } = parseAuthRequest(msg.payload);
          if (method === AuthMethod.OK) {
            continue;
          }
          if (method === AuthMethod.PASSWORD) {
            await this.protocol.sendMessage(MessageType.AUTH_RESPONSE, Buffer.from(this.config.password ?? ""), 0, true);
            continue;
          }
          if (method === AuthMethod.SCRAM_SHA_256) {
            if (!scram) {
              scram = new ScramExchange(this.config.user ?? "");
            }
            const clientFirst = Buffer.from(scram.clientFirstMessage(), "utf8");
            await this.protocol.sendMessage(MessageType.AUTH_RESPONSE, clientFirst, 0, true);
            continue;
          }
          throw new Error("Unsupported auth method");
        }
        case MessageType.AUTH_CONTINUE: {
          const { method, data } = parseAuthContinue(msg.payload);
          if (method !== AuthMethod.SCRAM_SHA_256 || !scram) {
            throw new Error("Unsupported auth continue");
          }
          const clientFinal = scram.handleServerFirst(this.config.password ?? "", data.toString("utf8"));
          await this.protocol.sendMessage(MessageType.AUTH_RESPONSE, Buffer.from(clientFinal, "utf8"), 0, true);
          continue;
        }
        case MessageType.AUTH_OK: {
          const { serverInfo } = parseAuthOk(msg.payload);
          this.protocol.setAttachment(msg.header.attachmentId, msg.header.txnId);
          if (scram && serverInfo.length && serverInfo.toString("utf8").startsWith("v=")) {
            scram.verifyServerFinal(serverInfo.toString("utf8"));
          }
          continue;
        }
        case MessageType.PARAMETER_STATUS: {
          const { name, value } = parseParameterStatus(msg.payload);
          this.parameters[name] = value;
          continue;
        }
        case MessageType.READY: {
          const { txnId } = parseReady(msg.payload);
          this.protocol.setTxnId(txnId);
          return;
        }
        case MessageType.ERROR:
          throw this.raiseProtocolError(msg.payload);
        default:
          continue;
      }
    }
  }

  private async applySchema(): Promise<void> {
    const schema = this.config.schema?.trim();
    if (!schema || schema.toLowerCase() === "public") {
      return;
    }
    const statement = buildSchemaStatement(schema);
    if (!statement) {
      return;
    }
    await this.sendSimpleQuery(statement);
    await this.drainUntilReady();
  }

  private async executeQuery(sql: string, params: any[], options?: QueryOptions): Promise<QueryResult> {
    if (params.length === 0) {
      await this.sendSimpleQuery(sql, options);
    } else {
      await this.sendExtendedQuery(sql, params, options);
    }

    const rows: any[] = [];
    let fields: FieldDef[] = [];
    let columns: ReturnType<typeof parseRowDescription> = [];
    let rowCount = -1;
    let command = "";

    while (true) {
      if (options?.signal?.aborted) {
        await this.cancelQuery();
        throw new ScratchbirdError("query canceled", "57014");
      }
      const msg = await this.protocol.recv();
      switch (msg.header.type) {
        case MessageType.ERROR:
          throw this.raiseProtocolError(msg.payload);
        case MessageType.ROW_DESCRIPTION:
          columns = parseRowDescription(msg.payload);
          fields = columns.map((col) => ({
            name: col.name,
            dataType: oidToString(col.typeOid),
            format: col.format === FORMAT_TEXT ? "text" : "binary",
            nullable: col.nullable,
            typeOid: col.typeOid,
            typeModifier: col.typeModifier,
          }));
          continue;
        case MessageType.DATA_ROW: {
          const values = parseDataRow(msg.payload, columns.length);
          rows.push(buildRow(columns, values));
          continue;
        }
        case MessageType.COMMAND_COMPLETE: {
          const parsed = parseCommandComplete(msg.payload);
          command = parsed.tag;
          rowCount = Number(parsed.rows);
          continue;
        }
        case MessageType.EMPTY_QUERY:
          continue;
        case MessageType.PARAMETER_STATUS: {
          const { name, value } = parseParameterStatus(msg.payload);
          this.parameters[name] = value;
          continue;
        }
        case MessageType.READY: {
          const { txnId } = parseReady(msg.payload);
          this.protocol.setTxnId(txnId);
          if (rowCount < 0) {
            rowCount = rows.length;
          }
          return { rows, rowCount, fields, command };
        }
        default:
          continue;
      }
    }
  }

  private async executePrepared(name: string, params: any[], options?: QueryOptions): Promise<QueryResult> {
    await this.sendBindExecute(name, params, options);

    const rows: any[] = [];
    let fields: FieldDef[] = [];
    let columns: ReturnType<typeof parseRowDescription> = [];
    let rowCount = -1;
    let command = "";

    while (true) {
      if (options?.signal?.aborted) {
        await this.cancelQuery();
        throw new ScratchbirdError("query canceled", "57014");
      }
      const msg = await this.protocol.recv();
      switch (msg.header.type) {
        case MessageType.ERROR:
          throw this.raiseProtocolError(msg.payload);
        case MessageType.ROW_DESCRIPTION:
          columns = parseRowDescription(msg.payload);
          fields = columns.map((col) => ({
            name: col.name,
            dataType: oidToString(col.typeOid),
            format: col.format === FORMAT_TEXT ? "text" : "binary",
            nullable: col.nullable,
            typeOid: col.typeOid,
            typeModifier: col.typeModifier,
          }));
          continue;
        case MessageType.DATA_ROW: {
          const values = parseDataRow(msg.payload, columns.length);
          rows.push(buildRow(columns, values));
          continue;
        }
        case MessageType.COMMAND_COMPLETE: {
          const parsed = parseCommandComplete(msg.payload);
          command = parsed.tag;
          rowCount = Number(parsed.rows);
          continue;
        }
        case MessageType.READY: {
          const { txnId } = parseReady(msg.payload);
          this.protocol.setTxnId(txnId);
          if (rowCount < 0) {
            rowCount = rows.length;
          }
          return { rows, rowCount, fields, command };
        }
        default:
          continue;
      }
    }
  }

  private async executeQueryStream(sql: string, params: any[], options?: QueryOptions): Promise<AsyncGenerator<any, void, void>> {
    if (params.length === 0) {
      await this.sendSimpleQuery(sql, options);
    } else {
      await this.sendExtendedQuery(sql, params, options);
    }

    const self = this;
    async function* iterator() {
      let columns: ReturnType<typeof parseRowDescription> = [];
      while (true) {
        if (options?.signal?.aborted) {
          await self.cancelQuery();
          throw new ScratchbirdError("query canceled", "57014");
        }
        const msg = await self.protocol.recv();
        switch (msg.header.type) {
          case MessageType.ERROR:
            throw self.raiseProtocolError(msg.payload);
          case MessageType.ROW_DESCRIPTION:
            columns = parseRowDescription(msg.payload);
            continue;
          case MessageType.DATA_ROW: {
            const values = parseDataRow(msg.payload, columns.length);
            yield buildRow(columns, values);
            continue;
          }
          case MessageType.READY: {
            const { txnId } = parseReady(msg.payload);
            self.protocol.setTxnId(txnId);
            return;
          }
          default:
            continue;
        }
      }
    }
    return iterator();
  }

  private async sendSimpleQuery(sql: string, options?: QueryOptions): Promise<void> {
    const flags = this.config.binaryTransfer ? QUERY_FLAG_BINARY_RESULT : 0;
    const maxRows = options?.maxRows ?? 0;
    const timeoutMs = options?.timeoutMs ?? 0;
    const payload = buildQueryPayload(sql, flags, maxRows, timeoutMs);
    await this.protocol.sendMessage(MessageType.QUERY, payload, 0, false);
  }

  private async sendExtendedQuery(sql: string, params: any[], options?: QueryOptions): Promise<void> {
    const paramValues: ParamValue[] = [];
    const paramTypes: number[] = [];
    for (const param of params) {
      const encoded = encodeParam(param);
      paramValues.push(encoded.param);
      paramTypes.push(encoded.oid);
    }
    const parsePayload = buildParsePayload("", sql, paramTypes);
    await this.protocol.sendMessage(MessageType.PARSE, parsePayload, 0, false);
    const resultFormats = this.config.binaryTransfer ? [FORMAT_BINARY] : [];
    const bindPayload = buildBindPayload("", "", paramValues, resultFormats);
    await this.protocol.sendMessage(MessageType.BIND, bindPayload, 0, false);
    const execPayload = buildExecutePayload("", options?.maxRows ?? 0);
    await this.protocol.sendMessage(MessageType.EXECUTE, execPayload, 0, false);
    await this.protocol.sendMessage(MessageType.SYNC, Buffer.alloc(0), 0, false);
  }

  private async sendBindExecute(statementName: string, params: any[], options?: QueryOptions): Promise<void> {
    const paramValues: ParamValue[] = [];
    for (const param of params) {
      const encoded = encodeParam(param);
      paramValues.push(encoded.param);
    }
    const resultFormats = this.config.binaryTransfer ? [FORMAT_BINARY] : [];
    const bindPayload = buildBindPayload("", statementName, paramValues, resultFormats);
    await this.protocol.sendMessage(MessageType.BIND, bindPayload, 0, false);
    const execPayload = buildExecutePayload("", options?.maxRows ?? 0);
    await this.protocol.sendMessage(MessageType.EXECUTE, execPayload, 0, false);
    await this.protocol.sendMessage(MessageType.SYNC, Buffer.alloc(0), 0, false);
  }

  private async cancelQuery(): Promise<void> {
    await this.protocol.sendMessage(MessageType.CANCEL, buildCancelPayload(0, 0), MSG_FLAG_URGENT, false);
  }

  private async drainUntilReady(): Promise<void> {
    while (true) {
      const msg = await this.protocol.recv();
      switch (msg.header.type) {
        case MessageType.ERROR:
          throw this.raiseProtocolError(msg.payload);
        case MessageType.READY: {
          const { txnId } = parseReady(msg.payload);
          this.protocol.setTxnId(txnId);
          return;
        }
        default:
          continue;
      }
    }
  }

  private raiseProtocolError(payload: Buffer): ScratchbirdError {
    try {
      const { sqlState, message, detail, hint } = parseErrorMessage(payload);
      const ErrorClass = mapSqlState(sqlState);
      const full = [message, detail ? `DETAIL: ${detail}` : "", hint ? `HINT: ${hint}` : ""]
        .filter(Boolean)
        .join("\n");
      return new ErrorClass(full || "query failed", sqlState, detail, hint);
    } catch {
      return new ScratchbirdError("query failed");
    }
  }
}

export class Pool {
  private config: ClientConfig;
  private max: number;
  private idleTimeoutMs: number;
  private active = 0;
  private idle: Array<{ client: Client; lastUsed: number }> = [];
  private waiters: Array<(client: Client) => void> = [];

  constructor(config?: ClientConfig | string) {
    const parsed = typeof config === "string" ? parseDsn(config) : {};
    const merged = { ...parsed, ...(typeof config === "object" ? config : {}) };
    this.config = merged;
    this.max = (merged as any).max ?? 10;
    this.idleTimeoutMs = (merged as any).idleTimeoutMs ?? 30000;
  }

  async connect(): Promise<Client> {
    const cached = this.idle.pop();
    if (cached) {
      return this.wrapClient(cached.client);
    }
    if (this.active < this.max) {
      this.active++;
      const client = new Client(this.config);
      await client.connect();
      return this.wrapClient(client);
    }
    return new Promise<Client>((resolve) => {
      this.waiters.push(resolve);
    });
  }

  async query<T = any>(text: string, params?: any[] | Record<string, any>, options?: QueryOptions): Promise<QueryResult<T>> {
    const client = await this.connect();
    try {
      return await client.query<T>(text, params, options);
    } finally {
      await (client as any).release();
    }
  }

  async end(): Promise<void> {
    for (const item of this.idle) {
      await item.client.end();
    }
    this.idle = [];
    this.active = 0;
  }

  private wrapClient(client: Client): Client {
    const pool = this;
    const release = async () => {
      const now = Date.now();
      pool.idle.push({ client, lastUsed: now });
      pool.cleanup();
      const waiter = pool.waiters.shift();
      if (waiter) {
        const next = pool.idle.pop();
        if (next) {
          waiter(pool.wrapClient(next.client));
        }
      }
    };
    (client as any).release = release;
    return client;
  }

  private cleanup(): void {
    const cutoff = Date.now() - this.idleTimeoutMs;
    const remaining: Array<{ client: Client; lastUsed: number }> = [];
    for (const item of this.idle) {
      if (item.lastUsed < cutoff) {
        item.client.end();
        this.active = Math.max(0, this.active - 1);
      } else {
        remaining.push(item);
      }
    }
    this.idle = remaining;
  }
}

function buildRow(columns: Array<{ name: string; typeOid: number; format: number }>, values: { data: Buffer | null }[]): Record<string, any> {
  const row: Record<string, any> = {};
  for (let i = 0; i < values.length; i++) {
    const column = columns[i];
    const data = values[i];
    const decoded = decodeValue(column.typeOid, data.data, column.format);
    if (column?.name) {
      row[column.name] = decoded;
    } else {
      row[i] = decoded;
    }
  }
  return row;
}

function buildSchemaStatement(schema: string): string {
  const trimmed = schema.trim();
  if (!trimmed) {
    return "";
  }
  if (trimmed.includes(",")) {
    const parts = trimmed
      .split(",")
      .map((part) => part.trim())
      .filter((part) => part.length > 0)
      .map((part) => quoteIdentifier(part));
    if (!parts.length) {
      return "";
    }
    return `SET SEARCH_PATH TO ${parts.join(", ")}`;
  }
  return `SET SCHEMA ${quoteIdentifier(trimmed)}`;
}

function quoteIdentifier(name: string): string {
  return `"${name.replace(/"/g, "\"\"")}"`;
}

function resolveSslMode(config: ClientConfig): string {
  if (config.ssl === false) return "disable";
  if (typeof config.ssl === "object") return config.sslmode ?? "require";
  if (config.ssl === true) return config.sslmode ?? "require";
  return config.sslmode ?? "require";
}

async function connectTcp(host: string, port: number, timeoutMs: number): Promise<net.Socket> {
  return new Promise((resolve, reject) => {
    const socket = net.connect({ host, port });
    socket.setNoDelay(true);
    socket.setKeepAlive(true);
    const timer = setTimeout(() => {
      socket.destroy();
      reject(new Error("Connection timeout"));
    }, timeoutMs);
    socket.once("error", (err) => {
      clearTimeout(timer);
      reject(err);
    });
    socket.once("connect", () => {
      clearTimeout(timer);
      resolve(socket);
    });
  });
}

async function upgradeTls(socket: net.Socket, host: string, sslMode: string, config: ClientConfig): Promise<tls.TLSSocket> {
  const rejectUnauthorized = sslMode === "verify-ca" || sslMode === "verify-full";
  const tlsOptions: tls.ConnectionOptions = {
    socket,
    servername: host,
    rejectUnauthorized,
    minVersion: "TLSv1.3",
    maxVersion: "TLSv1.3",
  };

  if (config.sslrootcert) {
    tlsOptions.ca = fs.readFileSync(config.sslrootcert);
  }
  if (config.sslcert) {
    tlsOptions.cert = fs.readFileSync(config.sslcert);
  }
  if (config.sslkey) {
    tlsOptions.key = fs.readFileSync(config.sslkey);
  }

  if (typeof config.ssl === "object") {
    Object.assign(tlsOptions, config.ssl);
  }

  const tlsSocket = tls.connect(tlsOptions);
  return new Promise<tls.TLSSocket>((resolve, reject) => {
    tlsSocket.once("secureConnect", () => resolve(tlsSocket));
    tlsSocket.once("error", (err) => reject(err));
  });
}
