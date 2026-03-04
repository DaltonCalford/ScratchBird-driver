// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
const test = require("node:test");
const assert = require("node:assert/strict");

const protocol = require("../dist/protocol.js");
const {
  Client,
  ScratchbirdError,
  ScratchbirdIntegrityError,
  ScratchbirdConnectionError,
} = require("../dist/index.js");

function errorPayload(fields) {
  const parts = [];
  for (const [tag, value] of Object.entries(fields)) {
    parts.push(Buffer.from(tag, "ascii"));
    parts.push(Buffer.from(value, "utf8"));
    parts.push(Buffer.from([0]));
  }
  parts.push(Buffer.from([0]));
  return Buffer.concat(parts);
}

test("raiseProtocolError maps SQLSTATE class and composes DETAIL/HINT text", () => {
  const client = new Client({ user: "me", database: "db" });
  const payload = errorPayload({
    S: "ERROR",
    C: "23505",
    M: "duplicate key value violates unique constraint",
    D: "Key (id)=(1) already exists.",
    H: "Use a new id.",
  });

  const err = client.raiseProtocolError(payload);
  assert.ok(err instanceof ScratchbirdIntegrityError);
  assert.equal(err.code, "23505");
  assert.equal(err.detail, "Key (id)=(1) already exists.");
  assert.equal(err.hint, "Use a new id.");
  assert.equal(
    err.message,
    "duplicate key value violates unique constraint\nDETAIL: Key (id)=(1) already exists.\nHINT: Use a new id.",
  );
});

test("raiseProtocolError falls back to query failed when message is empty", () => {
  const client = new Client({ user: "me", database: "db" });
  const payload = errorPayload({ S: "ERROR", C: "08006" });

  const err = client.raiseProtocolError(payload);
  assert.ok(err instanceof ScratchbirdConnectionError);
  assert.equal(err.code, "08006");
  assert.equal(err.message, "query failed");
});

test("raiseProtocolError falls back to generic query failed when parser throws", () => {
  const client = new Client({ user: "me", database: "db" });
  const original = protocol.parseErrorMessage;
  protocol.parseErrorMessage = () => {
    throw new Error("bad payload");
  };

  try {
    const err = client.raiseProtocolError(Buffer.from([1, 2, 3]));
    assert.ok(err instanceof ScratchbirdError);
    assert.equal(err.message, "query failed");
    assert.equal(err.code, undefined);
  } finally {
    protocol.parseErrorMessage = original;
  }
});
