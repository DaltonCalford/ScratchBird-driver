const test = require("node:test");
const assert = require("node:assert/strict");
const {
  parseDsn,
  substituteParameters,
  decodeValue,
  WireType,
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

test("substituteParameters formats arrays", () => {
  const sql = substituteParameters("select ?", [[1, "a", null]]);
  assert.equal(sql, "select ARRAY[1, 'a', NULL]");
});

test("decodeValue decodes int32", () => {
  const buf = Buffer.alloc(4);
  buf.writeInt32LE(42, 0);
  assert.equal(decodeValue(WireType.INT32, buf), 42);
});

test("decodeValue decodes arrays", () => {
  const buf = Buffer.from("{1, 2, 3}");
  assert.deepEqual(decodeValue(WireType.ARRAY, buf), [1, 2, 3]);
});
