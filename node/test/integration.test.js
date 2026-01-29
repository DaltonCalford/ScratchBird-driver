const test = require("node:test");
const assert = require("node:assert/strict");
const { Client } = require("../dist/index.js");

async function connectClient(t) {
  const url = process.env.SCRATCHBIRD_NODE_URL;
  if (!url) {
    t.skip("SCRATCHBIRD_NODE_URL not set");
    return null;
  }
  const client = new Client(url);
  await client.connect();
  return client;
}

test("connects and runs query", async (t) => {
  const client = await connectClient(t);
  if (!client) return;
  try {
    const res = await client.query("SELECT 1 as one");
    assert.equal(res.rows[0].one, 1);
  } finally {
    await client.end();
  }
});

test("prepared bind executes parameters", async (t) => {
  const client = await connectClient(t);
  if (!client) return;
  try {
    const res = await client.query("SELECT ?::INTEGER as value", [42]);
    assert.equal(res.rows[0].value, 42);
  } finally {
    await client.end();
  }
});

test("types fixture returns row", async (t) => {
  const client = await connectClient(t);
  if (!client) return;
  try {
    const res = await client.query("SELECT * FROM sb_conformance.type_coverage");
    assert.ok(res.rows.length >= 1);
  } finally {
    await client.end();
  }
});

test("cancel query", async (t) => {
  const client = await connectClient(t);
  if (!client) return;
  const cancelSql = process.env.SCRATCHBIRD_NODE_CANCEL_SQL;
  if (!cancelSql) {
    t.skip("SCRATCHBIRD_NODE_CANCEL_SQL not set");
    await client.end();
    return;
  }
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 200);
  try {
    await assert.rejects(client.query(cancelSql, [], { signal: controller.signal }));
  } finally {
    clearTimeout(timer);
    await client.end();
  }
});
