import net from "node:net";
import tls from "node:tls";
import fs from "node:fs";
import {
  AuthMethod,
  AuthStatus,
  MessageType,
  buildAuthRequest,
  buildBegin,
  buildCommit,
  buildConnectRequest,
  buildDisconnect,
  buildQuery,
  buildRollback,
  decodeHeader,
  parseAuthResponse,
  parseCommandComplete,
  parseConnectResponse,
  parseQueryError,
  parseQueryResult,
  parseRowData,
  parseRowDescription,
} from "./protocol";
import { ScramExchange } from "./scram";
import { parseDsn } from "./dsn";
import { substituteParameters } from "./sql";
import { decodeValue, wireTypeToString, ClientConfig, FieldDef, QueryResult } from "./types";
import { mapSqlState, ScratchbirdError } from "./errors";

interface Message {
  type: number;
  payload: Buffer;
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

  async connect(config: ClientConfig): Promise<void> {
    const host = config.host ?? "localhost";
    const port = config.port ?? 3092;
    const sslMode = resolveSslMode(config);

    let rawSocket = await connectTcp(host, port, config.connectTimeoutMs ?? 30000);

    if (sslMode !== "disable") {
      const requireTls = sslMode === "require" || sslMode === "verify-ca" || sslMode === "verify-full";
      try {
        const tlsSocket = await upgradeTls(rawSocket, host, sslMode, config);
        rawSocket = tlsSocket;
      } catch (err) {
        rawSocket.destroy();
        if (sslMode === "allow" || sslMode === "prefer") {
          rawSocket = await connectTcp(host, port, config.connectTimeoutMs ?? 30000);
        } else if (requireTls) {
          throw err;
        }
      }
    }

    if (config.socketTimeoutMs && config.socketTimeoutMs > 0) {
      rawSocket.setTimeout(config.socketTimeoutMs);
    }

    this.socket = rawSocket;
    this.reader = new SocketReader(rawSocket);
  }

  async send(data: Buffer): Promise<void> {
    if (!this.socket) throw new Error("Socket not connected");
    await new Promise<void>((resolve, reject) => {
      this.socket!.write(data, (err) => {
        if (err) reject(err);
        else resolve();
      });
    });
  }

  async recv(): Promise<Message> {
    if (!this.reader) throw new Error("Socket not connected");
    const header = await this.reader.readExact(12);
    const { type, length } = decodeHeader(header);
    const payload = length ? await this.reader.readExact(length) : Buffer.alloc(0);
    return { type, payload };
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
  private sessionId?: Buffer;
  private prepared = new Map<string, string>();
  private inTransaction = false;

  constructor(config?: ClientConfig | string) {
    const parsed = typeof config === "string" ? parseDsn(config) : {};
    this.config = { ...parsed, ...(typeof config === "object" ? config : {}) };
    if (!this.config.host) this.config.host = "localhost";
    if (!this.config.port) this.config.port = 3092;
    if (!this.config.applicationName) this.config.applicationName = "scratchbird_node";
  }

  async connect(): Promise<void> {
    if (!this.config.user || !this.config.database) {
      throw new Error("user and database are required");
    }
    await this.protocol.connect(this.config);
    const connectMsg = buildConnectRequest(
      this.config.database,
      this.config.applicationName ?? "scratchbird_node",
      process.pid,
    );
    await this.protocol.send(connectMsg);
    const response = await this.protocol.recv();
    if (response.type !== MessageType.CONNECT_RESPONSE) {
      throw new Error("Unexpected response to CONNECT_REQUEST");
    }
    const parsed = parseConnectResponse(response.payload);
    if (!parsed.success) {
      throw new Error(parsed.errorMessage || "connect failed");
    }
    this.sessionId = parsed.sessionId;
    await this.authenticate();
    this.connected = true;
  }

  async query<T = any>(text: string, params?: any[] | Record<string, any>): Promise<QueryResult<T>> {
    this.ensureConnected();
    const sql = substituteParameters(text, params);
    const result = await this.executeQuery(sql);
    return result as QueryResult<T>;
  }

  async queryStream(text: string, params?: any[] | Record<string, any>): Promise<AsyncGenerator<any, void, void>> {
    this.ensureConnected();
    const sql = substituteParameters(text, params);
    return this.executeQueryStream(sql);
  }

  async prepare(name: string, text: string, _paramTypes?: string[]): Promise<void> {
    if (!name) throw new Error("name is required");
    this.prepared.set(name, text);
  }

  async execute<T = any>(name: string, params?: any[] | Record<string, any>): Promise<QueryResult<T>> {
    const sql = this.prepared.get(name);
    if (!sql) throw new Error(`Unknown prepared statement: ${name}`);
    return this.query(sql, params);
  }

  async begin(): Promise<void> {
    this.ensureConnected();
    if (this.inTransaction) return;
    await this.protocol.send(buildBegin(this.sessionId!));
    await this.drainUntilComplete();
    this.inTransaction = true;
  }

  async commit(): Promise<void> {
    this.ensureConnected();
    if (!this.inTransaction) return;
    await this.protocol.send(buildCommit(this.sessionId!));
    await this.drainUntilComplete();
    this.inTransaction = false;
  }

  async rollback(): Promise<void> {
    this.ensureConnected();
    if (!this.inTransaction) return;
    await this.protocol.send(buildRollback(this.sessionId!));
    await this.drainUntilComplete();
    this.inTransaction = false;
  }

  async end(): Promise<void> {
    if (!this.connected) {
      this.protocol.close();
      return;
    }
    try {
      if (this.sessionId) {
        await this.protocol.send(buildDisconnect(this.sessionId));
      }
    } finally {
      this.protocol.close();
      this.connected = false;
      this.sessionId = undefined;
    }
  }

  private ensureConnected(): void {
    if (!this.connected || !this.sessionId) {
      throw new Error("Client is not connected");
    }
  }

  private async authenticate(): Promise<void> {
    const exchange = new ScramExchange(this.config.user ?? "");
    const clientFirst = Buffer.from(exchange.clientFirstMessage(), "utf8");
    const req = buildAuthRequest(this.sessionId!, this.config.user ?? "", AuthMethod.SCRAM_SHA_256, clientFirst);
    await this.protocol.send(req);

    let msg = await this.protocol.recv();
    if (msg.type !== MessageType.AUTH_RESPONSE) {
      throw new Error("Unexpected response to AUTH_REQUEST");
    }
    let auth = parseAuthResponse(msg.payload);
    if (auth.status !== AuthStatus.CONTINUE) {
      throw new Error(auth.errorMessage || "auth failed");
    }

    const serverFirst = auth.extra.toString("utf8");
    const clientFinal = exchange.handleServerFirst(this.config.password ?? "", serverFirst);
    const req2 = buildAuthRequest(
      this.sessionId!,
      this.config.user ?? "",
      AuthMethod.SCRAM_SHA_256,
      Buffer.from(clientFinal, "utf8"),
    );
    await this.protocol.send(req2);

    msg = await this.protocol.recv();
    if (msg.type !== MessageType.AUTH_RESPONSE) {
      throw new Error("Unexpected response to SCRAM final");
    }
    auth = parseAuthResponse(msg.payload);
    if (auth.status !== AuthStatus.OK) {
      throw new Error(auth.errorMessage || "auth failed");
    }
    if (auth.extra?.length) {
      exchange.verifyServerFinal(auth.extra.toString("utf8"));
    }
  }

  private async drainUntilComplete(): Promise<void> {
    while (true) {
      const msg = await this.protocol.recv();
      if (msg.type === MessageType.QUERY_ERROR) {
        throw this.raiseQueryError(msg.payload);
      }
      if (msg.type === MessageType.COMMAND_COMPLETE || msg.type === MessageType.END_OF_RESULTS) {
        return;
      }
    }
  }

  private async executeQuery(sql: string): Promise<QueryResult> {
    const rows: any[] = [];
    let fields: FieldDef[] = [];
    let columns: ReturnType<typeof parseRowDescription> = [];
    let rowCount = -1;
    let rowCountHint = -1;
    let command = "";

    await this.protocol.send(buildQuery(this.sessionId!, sql, 0));

    while (true) {
      const msg = await this.protocol.recv();
      if (msg.type === MessageType.QUERY_ERROR) {
        throw this.raiseQueryError(msg.payload);
      }
      if (msg.type === MessageType.QUERY_RESULT) {
        const parsed = parseQueryResult(msg.payload);
        rowCountHint = parsed.rowCount;
        continue;
      }
      if (msg.type === MessageType.ROW_DESCRIPTION) {
        columns = parseRowDescription(msg.payload);
        fields = columns.map((col) => ({
          name: col.name,
          dataType: wireTypeToString(col.wireType),
          format: col.formatCode === 1 ? "binary" : "text",
          nullable: true,
        }));
        continue;
      }
      if (msg.type === MessageType.ROW_DATA) {
        const values = parseRowData(msg.payload);
        const row = buildRow(columns, fields, values);
        rows.push(row);
        continue;
      }
      if (msg.type === MessageType.COMMAND_COMPLETE) {
        const parsed = parseCommandComplete(msg.payload);
        command = parsed.tag;
        rowCount = parsed.rowsAffected;
        continue;
      }
      if (msg.type === MessageType.END_OF_RESULTS) {
        break;
      }
    }

    if (rowCount < 0 && rowCountHint >= 0) {
      rowCount = rowCountHint;
    }
    if (rowCount < 0) {
      rowCount = rows.length;
    }

    return { rows, rowCount, fields, command };
  }

  private async executeQueryStream(sql: string): Promise<AsyncGenerator<any, void, void>> {
    await this.protocol.send(buildQuery(this.sessionId!, sql, 0));

    const self = this;
    async function* iterator() {
      let fields: FieldDef[] = [];
      let columns: ReturnType<typeof parseRowDescription> = [];
      while (true) {
        const msg = await self.protocol.recv();
        if (msg.type === MessageType.QUERY_ERROR) {
          throw self.raiseQueryError(msg.payload);
        }
        if (msg.type === MessageType.ROW_DESCRIPTION) {
          columns = parseRowDescription(msg.payload);
          fields = columns.map((col) => ({
            name: col.name,
            dataType: wireTypeToString(col.wireType),
            format: col.formatCode === 1 ? "binary" : "text",
            nullable: true,
          }));
          continue;
        }
        if (msg.type === MessageType.ROW_DATA) {
          const values = parseRowData(msg.payload);
          yield buildRow(columns, fields, values);
          continue;
        }
        if (msg.type === MessageType.END_OF_RESULTS) {
          break;
        }
      }
    }
    return iterator();
  }

  private raiseQueryError(payload: Buffer): ScratchbirdError {
    try {
      const { sqlstate, message, detail, hint } = parseQueryError(payload);
      const ErrorClass = mapSqlState(sqlstate);
      const full = [message, detail ? `DETAIL: ${detail}` : "", hint ? `HINT: ${hint}` : ""]
        .filter(Boolean)
        .join("\n");
      return new ErrorClass(full || "query failed", sqlstate, detail, hint);
    } catch (err) {
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

  async query<T = any>(text: string, params?: any[] | Record<string, any>): Promise<QueryResult<T>> {
    const client = await this.connect();
    try {
      return await client.query<T>(text, params);
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

function buildRow(
  columns: Array<{ wireType: number; name: string }>,
  fields: FieldDef[],
  values: { data: Buffer | null }[],
): Record<string, any> {
  const row: Record<string, any> = {};
  for (let i = 0; i < values.length; i++) {
    const field = fields[i];
    const data = values[i];
    const wireType = columns[i]?.wireType ?? mapFieldType(field);
    const decoded = decodeValue(wireType ?? 0, data.data);
    if (field && field.name) {
      row[field.name] = decoded;
    } else {
      row[i] = decoded;
    }
  }
  return row;
}

function mapFieldType(field?: FieldDef): number {
  if (!field) return 0xff;
  switch (field.dataType) {
    case "boolean":
      return 0x01;
    case "int16":
      return 0x02;
    case "int32":
      return 0x03;
    case "int64":
      return 0x04;
    case "float32":
      return 0x05;
    case "float64":
      return 0x06;
    case "decimal":
      return 0x07;
    case "varchar":
      return 0x08;
    case "char":
      return 0x09;
    case "bytea":
      return 0x0a;
    case "date":
      return 0x0b;
    case "time":
      return 0x0c;
    case "timestamp":
      return 0x0d;
    case "timestamptz":
      return 0x0e;
    case "interval":
      return 0x0f;
    case "uuid":
      return 0x10;
    case "json":
      return 0x11;
    case "jsonb":
      return 0x12;
    case "array":
      return 0x13;
    case "vector":
      return 0x16;
    case "money":
      return 0x17;
    case "xml":
      return 0x18;
    case "inet":
      return 0x19;
    case "cidr":
      return 0x1a;
    case "tsvector":
      return 0x1c;
    case "tsquery":
      return 0x1d;
    case "range":
      return 0x1e;
    default:
      return 0xff;
  }
}

function resolveSslMode(config: ClientConfig): string {
  if (config.ssl === false) return "disable";
  if (typeof config.ssl === "object") return config.sslmode ?? "require";
  if (config.ssl === true) return config.sslmode ?? "require";
  return config.sslmode ?? "prefer";
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
