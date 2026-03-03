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
  normalizeQuery,
  decodeValue,
  OID_INT4,
  OID_SB_VECTOR,
  FORMAT_BINARY,
  Client,
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
  client.collectResults = async () => ({ rows: [], rowCount: 0, fields: [], command: "SELECT" });

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
  client.collectResults = async () => ({ rows: [], rowCount: 0, fields: [], command: "SELECT" });
  client.prepared.set("stmt", { sql: "select :a, @b", paramCount: 2 });

  const normalized = client.nativeSQL("select :a, @b", { a: 1, b: 2 });
  await client.execute("stmt", { a: 1, b: 2 });

  assert.equal(normalized, "select $1, $2");
  assert.deepEqual(
    protocol.sent.map((entry) => entry.type),
    [MessageType.BIND, MessageType.EXECUTE, MessageType.SYNC],
  );
});
