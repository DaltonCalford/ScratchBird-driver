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
} = require("../dist/index.js");

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
