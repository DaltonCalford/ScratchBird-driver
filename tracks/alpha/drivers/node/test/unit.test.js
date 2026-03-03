// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
const test = require("node:test");
const assert = require("node:assert/strict");
const {
  parseDsn,
  normalizeCallableQuery,
  normalizeQuery,
  decodeValue,
  OID_INT4,
  OID_SB_VECTOR,
  FORMAT_BINARY,
  Client,
  METADATA_TABLES_QUERY,
  METADATA_SCHEMAS_QUERY,
  METADATA_INDEX_COLUMNS_QUERY,
  resolveMetadataCollectionQuery,
  buildMetadataSchemaTree,
} = require("../dist/index.js");
const { MessageType } = require("../dist/protocol.js");

test("parseDsn supports uri", () => {
  const cfg = parseDsn("scratchbird://user:pass@localhost:3092/db?sslmode=require");
  assert.equal(cfg.host, "localhost");
  assert.equal(cfg.port, 3092);
  assert.equal(cfg.user, "user");
  assert.equal(cfg.password, "pass");
  assert.equal(cfg.database, "db");
  assert.equal(cfg.sslmode, "require");
});

test("parseDsn supports key-value", () => {
  const cfg = parseDsn("host=127.0.0.1 port=3092 dbname=mydb user=me");
  assert.equal(cfg.host, "127.0.0.1");
  assert.equal(cfg.port, 3092);
  assert.equal(cfg.database, "mydb");
  assert.equal(cfg.user, "me");
});

test("parseDsn supports manager_proxy mode params", () => {
  const cfg = parseDsn("scratchbird://admin:secret@localhost:3090/mydb?front_door_mode=manager_proxy&manager_auth_token=token&manager_client_flags=7");
  assert.equal(cfg.frontDoorMode, "manager_proxy");
  assert.equal(cfg.managerAuthToken, "token");
  assert.equal(cfg.managerClientFlags, 7);
});

test("parseDsn supports metadataExpandSchemaParents aliases", () => {
  const fromUri = parseDsn("scratchbird://admin:secret@localhost:3090/mydb?metadata_expand_schema_parents=true");
  const fromKv = parseDsn("host=127.0.0.1 dbname=mydb user=me expandSchemaParents=1");
  assert.equal(fromUri.metadataExpandSchemaParents, true);
  assert.equal(fromKv.metadataExpandSchemaParents, true);
});

test("normalizeQuery rewrites positional", () => {
  const normalized = normalizeQuery("select ?", [1]);
  assert.equal(normalized.sql, "select $1");
  assert.deepEqual(normalized.params, [1]);
});

test("normalizeQuery rewrites named", () => {
  const normalized = normalizeQuery("select :a, @b", { a: 1, b: 2 });
  assert.equal(normalized.sql, "select $1, $2");
  assert.deepEqual(normalized.params, [1, 2]);
});

test("normalizeCallableQuery rewrites JDBC escape-call syntax", () => {
  const procedure = normalizeCallableQuery("{ call app.do_work(?, ?) }", [7, 9]);
  assert.equal(procedure.sql, "call app.do_work($1, $2)");
  assert.deepEqual(procedure.params, [7, 9]);

  const functionCall = normalizeCallableQuery("{ ? = call math.abs(?) }", [-3]);
  assert.equal(functionCall.sql, "select math.abs($1) as return_value");
  assert.deepEqual(functionCall.params, [-3]);
});

test("decodeValue decodes int4", () => {
  const buf = Buffer.alloc(4);
  buf.writeInt32LE(42, 0);
  assert.equal(decodeValue(OID_INT4, buf, FORMAT_BINARY), 42);
});

test("decodeValue decodes vector", () => {
  const vectorText = "[1, 2, 3]";
  const buf = Buffer.alloc(4 + vectorText.length);
  buf.writeUInt32LE(vectorText.length, 0);
  buf.write(vectorText, 4, "utf8");
  assert.deepEqual(decodeValue(OID_SB_VECTOR, buf, FORMAT_BINARY), [1, 2, 3]);
});

function makeReadyPayload(txnId) {
  const payload = Buffer.alloc(20);
  payload.writeUInt8(txnId === 0n ? 0 : 1, 0);
  payload.writeBigUInt64LE(txnId, 4);
  payload.writeBigUInt64LE(0n, 12);
  return payload;
}

function createMockProtocol(readyTxnIds = []) {
  const queue = readyTxnIds.map((txnId) => ({
    header: { type: MessageType.READY },
    payload: makeReadyPayload(txnId),
  }));
  return createQueuedProtocol(queue);
}

function createQueuedProtocol(queueEntries = []) {
  const queue = [...queueEntries];
  const sent = [];
  let txnId = 0n;
  return {
    sent,
    async sendMessage(type, payload, flags, forceZero) {
      sent.push({ type, payload, flags, forceZero });
      return sent.length;
    },
    async recv() {
      if (!queue.length) {
        throw new Error("mock receive queue exhausted");
      }
      return queue.shift();
    },
    setTxnId(nextTxnId) {
      txnId = nextTxnId;
    },
    getTxnId() {
      return txnId;
    },
    setAttachment(_id, nextTxnId) {
      txnId = nextTxnId;
    },
    close() {},
  };
}

function makeReadyMessage(txnId) {
  return {
    header: { type: MessageType.READY },
    payload: makeReadyPayload(txnId),
  };
}

function makeCommandCompletePayload(tag, rows, lastId = 0n, commandType = 0) {
  const tagBuffer = Buffer.from(tag, "utf8");
  const payload = Buffer.alloc(20 + tagBuffer.length + 1);
  payload.writeUInt8(commandType, 0);
  payload.writeBigUInt64LE(rows, 4);
  payload.writeBigUInt64LE(lastId, 12);
  tagBuffer.copy(payload, 20);
  payload[payload.length - 1] = 0;
  return payload;
}

function parseSqlFromParsePayload(payload) {
  const nameLen = payload.readUInt32LE(0);
  const sqlLenOffset = 4 + nameLen;
  const sqlLen = payload.readUInt32LE(sqlLenOffset);
  return payload.subarray(sqlLenOffset + 4, sqlLenOffset + 4 + sqlLen).toString("utf8");
}

test("transaction lifecycle enforces begin-before-commit semantics", async () => {
  const client = new Client({ user: "me", database: "db" });
  const protocol = createMockProtocol([42n, 0n]);
  client.connected = true;
  client.protocol = protocol;

  await assert.rejects(() => client.commitTransaction(), (err) => err && err.code === "25000");

  await client.beginTransaction();
  await assert.rejects(() => client.beginTransaction(), (err) => err && err.code === "25001");
  await client.commitTransaction();

  assert.deepEqual(
    protocol.sent.map((entry) => entry.type),
    [MessageType.TXN_BEGIN, MessageType.TXN_COMMIT],
  );
});

test("savepoint flows require an active transaction and a non-empty name", async () => {
  const client = new Client({ user: "me", database: "db" });
  const protocol = createMockProtocol([88n, 88n, 88n, 88n, 0n]);
  client.connected = true;
  client.protocol = protocol;

  await assert.rejects(() => client.savepoint("sp"), (err) => err && err.code === "25000");

  await client.beginTransaction();
  await assert.rejects(() => client.savepoint("   "), (err) => err && err.code === "42601");
  await client.savepoint("sp");
  await client.releaseSavepoint("sp");
  await client.rollbackToSavepoint("sp");
  await client.rollbackTransaction();

  assert.deepEqual(
    protocol.sent.map((entry) => entry.type),
    [MessageType.TXN_BEGIN, MessageType.TXN_SAVEPOINT, MessageType.TXN_RELEASE, MessageType.TXN_ROLLBACK_TO, MessageType.TXN_ROLLBACK],
  );
});

test("extended query path rewrites named parameters and sends parse/bind/execute/sync", async () => {
  const client = new Client({ user: "me", database: "db" });
  const protocol = createMockProtocol();
  client.connected = true;
  client.protocol = protocol;
  client.describeStatement = async () => 1;
  client.collectResults = async () => ({ rows: [], rowCount: 0, fields: [], command: "SELECT", lastId: null });

  await client.query("select :value", { value: 7 });

  assert.deepEqual(
    protocol.sent.map((entry) => entry.type),
    [MessageType.PARSE, MessageType.BIND, MessageType.EXECUTE, MessageType.SYNC],
  );
  assert.equal(parseSqlFromParsePayload(protocol.sent[0].payload), "select $1");
});

test("prepared execute path sends bind/execute/sync and nativeSQL normalizes aliases", async () => {
  const client = new Client({ user: "me", database: "db" });
  const protocol = createMockProtocol();
  client.connected = true;
  client.protocol = protocol;
  client.collectResults = async () => ({ rows: [], rowCount: 0, fields: [], command: "SELECT", lastId: null });
  client.prepared.set("stmt", { sql: "select :a, @b", paramCount: 2 });

  const normalized = client.nativeSQL("select :a, @b", { a: 1, b: 2 });
  await client.execute("stmt", { a: 1, b: 2 });

  assert.equal(normalized, "select $1, $2");
  assert.deepEqual(
    protocol.sent.map((entry) => entry.type),
    [MessageType.BIND, MessageType.EXECUTE, MessageType.SYNC],
  );
});

function findTreeNode(nodes, path) {
  for (const node of nodes) {
    if (node.path === path) {
      return node;
    }
  }
  return null;
}

test("metadata query resolver supports collection aliases", () => {
  assert.equal(resolveMetadataCollectionQuery(), METADATA_TABLES_QUERY);
  assert.equal(resolveMetadataCollectionQuery("schemas"), METADATA_SCHEMAS_QUERY);
  assert.equal(resolveMetadataCollectionQuery("indexcolumns"), METADATA_INDEX_COLUMNS_QUERY);
  assert.throws(() => resolveMetadataCollectionQuery("privileges"), /not supported/);
});

test("getSchema routes metadata collections and rejects unsupported collections", async () => {
  const client = new Client({ user: "me", database: "db", metadataExpandSchemaParents: false });
  client.connected = true;
  const issuedSql = [];
  client.query = async (sql) => {
    issuedSql.push(sql);
    return { rows: [], rowCount: 0, fields: [], command: "SELECT", lastId: null };
  };

  await client.getSchema("index_columns");
  await assert.rejects(() => client.getSchema("privileges"), (err) => err && err.code === "0A000");

  assert.deepEqual(issuedSql, [METADATA_INDEX_COLUMNS_QUERY]);
});

test("getSchema expands schema parents when metadataExpandSchemaParents is enabled", async () => {
  const client = new Client({ user: "me", database: "db", metadataExpandSchemaParents: true });
  client.connected = true;
  client.query = async () => ({
    rows: [
      { schema_id: 1, schema_name: "users.alice.dev", owner_id: 7, default_tablespace_id: 3 },
      { schema_id: 2, schema_name: "sys", owner_id: 7, default_tablespace_id: 3 },
      { schema_id: 3, schema_name: "users.bob.dev", owner_id: 7, default_tablespace_id: 3 },
      { schema_id: 4, schema_name: "users.bob.dev", owner_id: 7, default_tablespace_id: 3 },
    ],
    rowCount: 4,
    fields: [],
    command: "SELECT",
    lastId: null,
  });

  const schemas = await client.getSchema("schemas");

  assert.equal(schemas.rowCount, 6);
  assert.deepEqual(
    schemas.rows.map((row) => row.schema_name),
    ["users", "users.alice", "users.alice.dev", "sys", "users.bob", "users.bob.dev"],
  );
  assert.equal(schemas.rows[0].schema_id, null);
  assert.equal(schemas.rows[2].schema_id, 1);
});

test("buildMetadataSchemaTree preserves recursive ancestry and per-parent uniqueness", () => {
  const tree = buildMetadataSchemaTree(
    [
      { schema_name: "users.alice.dev" },
      { schema_name: "users.alice.prod" },
      { schema_name: "users.bob.dev" },
      { schema_name: "users.bob.dev" },
      { schema_name: "analytics.dev" },
      { schema_name: "analytics.prod" },
    ],
    { database: "main" },
  );

  assert.equal(tree.database, "main");
  assert.deepEqual(
    tree.schemas.map((node) => node.path),
    ["users", "analytics"],
  );

  const users = findTreeNode(tree.schemas, "users");
  assert.ok(users);
  assert.equal(users.terminal, false);

  const alice = findTreeNode(users.children, "users.alice");
  const bob = findTreeNode(users.children, "users.bob");
  assert.ok(alice);
  assert.ok(bob);
  assert.deepEqual(
    alice.children.map((node) => node.path),
    ["users.alice.dev", "users.alice.prod"],
  );
  assert.deepEqual(
    bob.children.map((node) => node.path),
    ["users.bob.dev"],
  );

  const aliceDev = findTreeNode(alice.children, "users.alice.dev");
  const bobDev = findTreeNode(bob.children, "users.bob.dev");
  assert.ok(aliceDev);
  assert.ok(bobDev);
  assert.equal(aliceDev.terminal, true);
  assert.equal(bobDev.terminal, true);
});

test("getSchemaTree builds metadata-only tree from schema rows", async () => {
  const client = new Client({ user: "me", database: "db_main" });
  client.connected = true;
  client.getSchema = async () => ({
    rows: [{ schema_name: "sys" }, { schema_name: "users.alice.dev" }, { schema_name: "users.bob.dev" }],
    rowCount: 3,
    fields: [],
    command: "SELECT",
    lastId: null,
  });

  const tree = await client.getSchemaTree();
  assert.equal(tree.database, "db_main");
  assert.deepEqual(
    tree.schemas.map((node) => node.path),
    ["sys", "users"],
  );

  const users = findTreeNode(tree.schemas, "users");
  assert.ok(users);
  assert.deepEqual(
    users.children.map((node) => node.path),
    ["users.alice", "users.bob"],
  );
});
