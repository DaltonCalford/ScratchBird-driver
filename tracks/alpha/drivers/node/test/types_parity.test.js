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
  FORMAT_BINARY,
  FORMAT_TEXT,
  OID_BOOL,
  OID_BYTEA,
  OID_INT4,
  OID_INT8,
  OID_NUMERIC,
  OID_MONEY,
  OID_JSON,
  OID_JSONB,
  OID_UUID,
  OID_INT8RANGE,
  OID_SB_VECTOR,
  ScratchbirdJsonb,
  ScratchbirdRange,
  encodeParam,
  decodeValue,
} = require("../dist/index.js");

function lengthPrefixed(value) {
  const data = Buffer.isBuffer(value) ? value : Buffer.from(value, "utf8");
  const out = Buffer.alloc(4 + data.length);
  out.writeUInt32LE(data.length, 0);
  data.copy(out, 4);
  return out;
}

test("encodeParam covers representative primitive and structured inputs", () => {
  {
    const encoded = encodeParam(true);
    assert.equal(encoded.oid, OID_BOOL);
    assert.equal(encoded.param.format, FORMAT_BINARY);
    assert.deepEqual(Array.from(encoded.param.data ?? Buffer.alloc(0)), [1]);
  }
  {
    const encoded = encodeParam(42);
    assert.equal(encoded.oid, OID_INT4);
    assert.equal(encoded.param.data.readInt32LE(0), 42);
  }
  {
    const encoded = encodeParam(2147483648);
    assert.equal(encoded.oid, OID_INT8);
    assert.equal(encoded.param.data.readBigInt64LE(0), 2147483648n);
  }
  {
    const encoded = encodeParam({ role: "admin", active: true });
    assert.equal(encoded.oid, OID_JSON);
    assert.equal(encoded.param.data.readUInt32LE(0) > 0, true);
  }
  {
    const encoded = encodeParam([1, 2, 3]);
    assert.equal(encoded.oid, OID_SB_VECTOR);
    assert.equal(encoded.param.data.subarray(4).toString("utf8"), "[1,2,3]");
  }
});

test("encodeParam rejects unsupported numeric and range inputs", () => {
  assert.throws(() => encodeParam(Number.POSITIVE_INFINITY), /must be finite/);
  assert.throws(() => encodeParam(new ScratchbirdRange({ empty: true })), /cannot be inferred/);
});

test("decodeValue decodes jsonb wrapper and bytea payload", () => {
  const jsonb = decodeValue(OID_JSONB, lengthPrefixed('{"k":1}'), FORMAT_BINARY);
  assert.ok(jsonb instanceof ScratchbirdJsonb);
  assert.equal(jsonb.raw.toString("utf8"), '{"k":1}');

  const bytes = decodeValue(OID_BYTEA, lengthPrefixed(Buffer.from([1, 2, 3, 4])), FORMAT_BINARY);
  assert.ok(Buffer.isBuffer(bytes));
  assert.deepEqual(Array.from(bytes), [1, 2, 3, 4]);
});

test("decodeValue decodes numeric, money, uuid, and vector", () => {
  const numeric = decodeValue(OID_NUMERIC, lengthPrefixed("12345.678"), FORMAT_BINARY);
  assert.equal(numeric, "12345.678");

  const moneyBuf = Buffer.alloc(8);
  moneyBuf.writeBigInt64LE(12345n, 0);
  const money = decodeValue(OID_MONEY, moneyBuf, FORMAT_BINARY);
  assert.equal(money, "123.45");

  const uuidBytes = Buffer.from("00112233445566778899aabbccddeeff", "hex");
  const uuid = decodeValue(OID_UUID, uuidBytes, FORMAT_BINARY);
  assert.equal(uuid, "00112233-4455-6677-8899-aabbccddeeff");

  const vector = decodeValue(OID_SB_VECTOR, lengthPrefixed("[0.5, 1.5, 2.5]"), FORMAT_BINARY);
  assert.deepEqual(vector, [0.5, 1.5, 2.5]);
});

test("decodeValue decodes int8range boundaries", () => {
  const payload = Buffer.alloc(4 + 4 + 8 + 4 + 8);
  payload[0] = 0;
  payload.writeInt32LE(8, 4);
  payload.writeBigInt64LE(10n, 8);
  payload.writeInt32LE(8, 16);
  payload.writeBigInt64LE(20n, 20);

  const range = decodeValue(OID_INT8RANGE, payload, FORMAT_BINARY);
  assert.ok(range instanceof ScratchbirdRange);
  assert.equal(range.lower, 10n);
  assert.equal(range.upper, 20n);
  assert.equal(range.empty, false);
  assert.equal(range.lowerInclusive, false);
  assert.equal(range.upperInclusive, false);
});

test("decodeValue decodes composite row payload", () => {
  const OID_RECORD = 2249;
  const payload = Buffer.alloc(4 + 4 + 4 + 4);
  payload.writeInt32LE(1, 0);
  payload.writeUInt32LE(OID_INT4, 4);
  payload.writeInt32LE(4, 8);
  payload.writeInt32LE(77, 12);

  const composite = decodeValue(OID_RECORD, payload, FORMAT_BINARY);
  assert.equal(composite.fields.length, 1);
  assert.equal(composite.fields[0].oid, OID_INT4);
  assert.equal(composite.fields[0].value, 77);
});

test("decodeValue unknown-type heuristics parse text and arrays", () => {
  assert.equal(decodeValue(0, Buffer.from("true", "utf8"), FORMAT_TEXT), true);
  assert.equal(decodeValue(0, Buffer.from("42", "utf8"), FORMAT_TEXT), 42);
  assert.equal(decodeValue(0, Buffer.from("9007199254740993", "utf8"), FORMAT_TEXT), 9007199254740993n);
  assert.deepEqual(decodeValue(0, lengthPrefixed("{1,2,3}"), FORMAT_BINARY), [1, 2, 3]);
});
