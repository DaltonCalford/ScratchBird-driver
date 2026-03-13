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
  Pool,
  METADATA_TABLES_QUERY,
  METADATA_SCHEMAS_QUERY,
  METADATA_INDEX_COLUMNS_QUERY,
  METADATA_PRIMARY_KEYS_QUERY,
  METADATA_FOREIGN_KEYS_QUERY,
  METADATA_TABLE_PRIVILEGES_QUERY,
  METADATA_ROUTINES_QUERY,
  METADATA_TYPE_INFO_QUERY,
  filterMetadataRowsByRestrictions,
  resolveMetadataCollectionQuery,
  shapeMetadataRowsForCollection,
  buildMetadataSchemaTree,
  mapSqlState,
  ScratchbirdSyntaxError,
  ScratchbirdConnectionError,
  ScratchbirdDataError,
  ScratchbirdError,
  CircuitBreaker,
  KeepaliveManager,
  LeakDetector,
  TelemetryCollector,
} = require("../dist/index.js");
const { MessageType, applyAuthPluginSelection } = require("../dist/protocol.js");

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

test("parseDsn supports auth plugin and pinning params", () => {
  const cfg = parseDsn(
    "scratchbird://user:pass@localhost:3092/db"
      + "?connect_client_flags=257"
      + "&auth_method_id=scratchbird.auth.proxy_assertion"
      + "&auth_method_payload=opaque"
      + "&auth_payload_json=%7B%22subject%22%3A%22alice%22%7D"
      + "&auth_payload_b64=YWJj"
      + "&auth_provider_profile=corp_primary"
      + "&auth_required_methods=SCRAM_SHA_256%2CTOKEN"
      + "&auth_forbidden_methods=MD5"
      + "&auth_require_channel_binding=true"
      + "&workload_identity_token=jwt-token"
      + "&proxy_principal_assertion=signed-assertion",
  );
  assert.equal(cfg.connectClientFlags, 257);
  assert.equal(cfg.authMethodId, "scratchbird.auth.proxy_assertion");
  assert.equal(cfg.authMethodPayload, "opaque");
  assert.equal(cfg.authPayloadJson, "{\"subject\":\"alice\"}");
  assert.equal(cfg.authPayloadB64, "YWJj");
  assert.equal(cfg.authProviderProfile, "corp_primary");
  assert.equal(cfg.authRequiredMethods, "SCRAM_SHA_256,TOKEN");
  assert.equal(cfg.authForbiddenMethods, "MD5");
  assert.equal(cfg.authRequireChannelBinding, true);
  assert.equal(cfg.workloadIdentityToken, "jwt-token");
  assert.equal(cfg.proxyPrincipalAssertion, "signed-assertion");
});

test("applyAuthPluginSelection sets extended params and rejects invalid namespace", () => {
  const params = {};
  applyAuthPluginSelection(params, {
    methodId: "scratchbird.auth.proxy_assertion",
    methodPayload: "opaque",
    payloadJson: "{\"subject\":\"alice\"}",
    payloadB64: "YWJj",
    providerProfile: "corp_primary",
    requiredMethods: "SCRAM_SHA_256,TOKEN",
    forbiddenMethods: "MD5",
    requireChannelBinding: true,
    workloadIdentityToken: "jwt-token",
    proxyPrincipalAssertion: "signed-assertion",
  });
  assert.equal(params.auth_method_id, "scratchbird.auth.proxy_assertion");
  assert.equal(params.auth_method_payload, "opaque");
  assert.equal(params.auth_payload_json, "{\"subject\":\"alice\"}");
  assert.equal(params.auth_payload_b64, "YWJj");
  assert.equal(params.auth_provider_profile, "corp_primary");
  assert.equal(params.auth_required_methods, "SCRAM_SHA_256,TOKEN");
  assert.equal(params.auth_forbidden_methods, "MD5");
  assert.equal(params.auth_require_channel_binding, "1");
  assert.equal(params.workload_identity_token, "jwt-token");
  assert.equal(params.proxy_principal_assertion, "signed-assertion");

  assert.throws(
    () => applyAuthPluginSelection({}, { methodId: "invalid.namespace" }),
    /Invalid auth_method_id namespace/,
  );
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

function parseSqlFromQueryPayload(payload) {
  const sqlWithTerminator = payload.subarray(12).toString("utf8");
  return sqlWithTerminator.endsWith("\u0000")
    ? sqlWithTerminator.slice(0, -1)
    : sqlWithTerminator;
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

test("autocommit toggle drives implicit begin and commit", async () => {
  const client = new Client({ user: "me", database: "db" });
  const protocol = createMockProtocol([0n, 77n, 88n, 88n]);
  client.connected = true;
  client.protocol = protocol;
  client.collectResults = async () => ({ rows: [], rowCount: 0, fields: [], command: "SELECT", lastId: null });

  assert.equal(client.getAutoCommit(), true);
  await client.setAutoCommit(false);
  await client.query("select 1");
  assert.equal(client.getAutoCommit(), false);
  assert.equal(client.transactionActive, true);

  await client.setAutoCommit(true);
  assert.equal(client.getAutoCommit(), true);
  assert.equal(client.transactionActive, true);
  assert.deepEqual(
    protocol.sent.map((entry) => entry.type),
    [MessageType.SET_OPTION, MessageType.TXN_BEGIN, MessageType.QUERY, MessageType.TXN_COMMIT, MessageType.SET_OPTION],
  );
});

test("setSessionSchema null resets to users.public", async () => {
  const client = new Client({ user: "me", database: "db" });
  const protocol = createMockProtocol([0n]);
  client.connected = true;
  client.protocol = protocol;

  await client.setSessionSchema(null);
  assert.equal(client.getSessionSchema(), null);
  assert.equal(client.config.schema, undefined);
  assert.equal(protocol.sent.length, 1);
  assert.equal(protocol.sent[0].type, MessageType.QUERY);
  assert.equal(parseSqlFromQueryPayload(protocol.sent[0].payload), 'SET SCHEMA "users.public"');
});

test("setSessionSchema applies schema statement on connected clients", async () => {
  const client = new Client({ user: "me", database: "db" });
  const protocol = createMockProtocol([0n]);
  client.connected = true;
  client.protocol = protocol;

  await client.setSessionSchema("analytics.dev");
  assert.equal(client.getSessionSchema(), "analytics.dev");
  assert.equal(client.config.schema, "analytics.dev");
  assert.equal(protocol.sent.length, 1);
  assert.equal(protocol.sent[0].type, MessageType.QUERY);
  assert.equal(parseSqlFromQueryPayload(protocol.sent[0].payload), 'SET SCHEMA "analytics.dev"');
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

test("prepare supports statement name reuse and refreshes cached SQL", async () => {
  const client = new Client({ user: "me", database: "db" });
  const protocol = createMockProtocol();
  client.connected = true;
  client.protocol = protocol;
  client.describeStatement = async () => 0;

  await client.prepare("reuse_stmt", "select 1 as value");
  await client.prepare("reuse_stmt", "select 2 as value");

  assert.equal(client.prepared.get("reuse_stmt").sql, "select 2 as value");
  assert.deepEqual(
    protocol.sent.map((entry) => entry.type),
    [MessageType.PARSE, MessageType.PARSE],
  );
});

test("nativeSQL and nativeCallableSQL wrap normalization failures as syntax errors", () => {
  const client = new Client({ user: "me", database: "db" });

  assert.throws(
    () => client.nativeSQL("select ?", []),
    (err) => err instanceof ScratchbirdSyntaxError && err.code === "07001",
  );

  assert.throws(
    () => client.nativeCallableSQL("{ ? = call abs( }", []),
    (err) => err instanceof ScratchbirdSyntaxError && err.code === "07001",
  );
});

test("queryMulti returns independent result sets and preserves generated keys", async () => {
  const client = new Client({ user: "me", database: "db" });
  const protocol = createQueuedProtocol([
    {
      header: { type: MessageType.COMMAND_COMPLETE },
      payload: makeCommandCompletePayload("INSERT", 1n, 101n),
    },
    {
      header: { type: MessageType.COMMAND_COMPLETE },
      payload: makeCommandCompletePayload("INSERT", 1n, 202n),
    },
    makeReadyMessage(0n),
  ]);
  client.connected = true;
  client.protocol = protocol;

  const results = await client.queryMulti("insert into t values (1); insert into t values (2)");
  assert.equal(results.length, 2);
  assert.equal(results[0].command, "INSERT");
  assert.equal(results[0].lastId, 101n);
  assert.equal(results[1].lastId, 202n);
});

test("queryBatch aggregates per-item command summaries", async () => {
  const client = new Client({ user: "me", database: "db" });
  client.connected = true;
  client.query = async (_sql, params) => ({
    rows: [],
    rowCount: 1,
    fields: [],
    command: "INSERT",
    lastId: BigInt(Array.isArray(params) ? params[0] : 0),
  });

  const batch = await client.queryBatch("insert into t(id) values (?)", [[11], [22], [33]]);
  assert.equal(batch.items.length, 3);
  assert.equal(batch.totalRowCount, 3);
  assert.deepEqual(
    batch.items.map((item) => item.lastId),
    [11n, 22n, 33n],
  );
});

test("queryBatch and executeBatch reject empty batch parameters", async () => {
  const client = new Client({ user: "me", database: "db" });
  client.connected = true;
  client.prepared.set("stmt", { sql: "select ?::integer", paramCount: 1 });

  await assert.rejects(
    () => client.queryBatch("select ?::integer", []),
    (err) => err instanceof ScratchbirdSyntaxError && err.code === "07001",
  );
  await assert.rejects(
    () => client.executeBatch("stmt", []),
    (err) => err instanceof ScratchbirdSyntaxError && err.code === "07001",
  );
});

test("executeWithGeneratedKeys returns non-zero generated keys", async () => {
  const client = new Client({ user: "me", database: "db" });
  client.connected = true;
  client.executeQueryMulti = async () => [
    { rows: [], rowCount: 1, fields: [], command: "INSERT", lastId: 0n },
    { rows: [], rowCount: 1, fields: [], command: "INSERT", lastId: 101n },
    { rows: [], rowCount: 1, fields: [], command: "INSERT", lastId: null },
    { rows: [], rowCount: 1, fields: [], command: "INSERT", lastId: 202n },
  ];

  const keys = await client.executeWithGeneratedKeys("insert into t values (1); insert into t values (2)");
  assert.deepEqual(keys, [101n, 202n]);
});

test("call rewrites escape syntax and delegates through executeQuery", async () => {
  const client = new Client({ user: "me", database: "db" });
  client.connected = true;
  let observedSql = null;
  let observedParams = null;
  client.executeQuery = async (sql, params) => {
    observedSql = sql;
    observedParams = params;
    return { rows: [{ return_value: 3 }], rowCount: 1, fields: [], command: "SELECT", lastId: null };
  };

  const result = await client.call("{ ? = call math.abs(?) }", [-3]);
  assert.equal(observedSql, "select math.abs($1) as return_value");
  assert.deepEqual(observedParams, [-3]);
  assert.equal(result.rows[0].return_value, 3);
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
  assert.equal(resolveMetadataCollectionQuery("pk"), METADATA_PRIMARY_KEYS_QUERY);
  assert.equal(resolveMetadataCollectionQuery("foreign_keys"), METADATA_FOREIGN_KEYS_QUERY);
  assert.equal(resolveMetadataCollectionQuery("table_privileges"), METADATA_TABLE_PRIVILEGES_QUERY);
  assert.equal(resolveMetadataCollectionQuery("routines"), METADATA_ROUTINES_QUERY);
  assert.equal(resolveMetadataCollectionQuery("types"), METADATA_TYPE_INFO_QUERY);
  assert.throws(() => resolveMetadataCollectionQuery("no_such_metadata"), /not supported/);
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
  await client.getSchema("foreign_keys");
  await client.getSchema("table_privileges");
  await client.getSchema("routines");
  await assert.rejects(() => client.getSchema("privileges_not_supported"), (err) => err && err.code === "0A000");

  assert.deepEqual(issuedSql, [METADATA_INDEX_COLUMNS_QUERY, METADATA_FOREIGN_KEYS_QUERY, METADATA_TABLE_PRIVILEGES_QUERY, METADATA_ROUTINES_QUERY]);
});

test("metadata convenience wrappers forward collection-specific restrictions", async () => {
  const client = new Client({ user: "me", database: "db" });
  client.connected = true;
  const captured = [];
  client.getSchema = async (collection, restrictions) => {
    captured.push({ collection, restrictions });
    return { rows: [], rowCount: 0, fields: [], command: "SELECT", lastId: null };
  };

  await client.procedures("main", "users", "upsert_event");
  await client.functions("main", "users", "event_count");
  await client.routines("main", "users", "event_count");
  await client.tablePrivileges("main", "users", "events");
  await client.columnPrivileges("main", "users", "events", "event_id");
  await client.typeInfo("INTEGER");

  assert.deepEqual(captured, [
    { collection: "procedures", restrictions: { catalog: "main", schema: "users", procedure: "upsert_event" } },
    { collection: "functions", restrictions: { catalog: "main", schema: "users", function: "event_count" } },
    { collection: "routines", restrictions: { catalog: "main", schema: "users", routine: "event_count" } },
    { collection: "table_privileges", restrictions: { catalog: "main", schema: "users", table: "events" } },
    { collection: "column_privileges", restrictions: { catalog: "main", schema: "users", table: "events", column: "event_id" } },
    { collection: "type_info", restrictions: { type: "INTEGER" } },
  ]);
});

test("queryMetadata shapes JDBC-style aliases and applies catalog/schema restrictions", async () => {
  const client = new Client({ user: "me", database: "main_catalog" });
  client.connected = true;
  client.query = async () => ({
    rows: [
      { table_id: 1, schema_name: "sys", table_name: "sessions", table_type: "SYSTEM VIEW", owner_id: 10 },
      { table_id: 2, schema_name: "users", table_name: "events", table_type: "TABLE", owner_id: 10 },
    ],
    rowCount: 2,
    fields: [],
    command: "SELECT",
    lastId: null,
  });

  const rows = await client.queryMetadata("tables", { catalog: "main_catalog", schema: "users" });
  assert.equal(rows.rowCount, 1);
  assert.equal(rows.rows[0].TABLE_CAT, "main_catalog");
  assert.equal(rows.rows[0].TABLE_SCHEM, "users");
  assert.equal(rows.rows[0].TABLE_NAME, "events");
  assert.equal(rows.rows[0].TABLE_TYPE, "TABLE");
});

test("shapeMetadataRowsForCollection enriches rows for DDL/editor compatibility fields", () => {
  const columns = shapeMetadataRowsForCollection(
    [
      {
        schema_name: "users",
        table_name: "events",
        column_name: "event_id",
        data_type_id: 23,
        data_type_name: "int4",
        ordinal_position: 1,
        is_nullable: false,
        default_value: null,
      },
    ],
    "columns",
    { database: "main_catalog" },
  );
  assert.equal(columns[0].TABLE_CAT, "main_catalog");
  assert.equal(columns[0].TABLE_SCHEM, "users");
  assert.equal(columns[0].TABLE_NAME, "events");
  assert.equal(columns[0].COLUMN_NAME, "event_id");
  assert.equal(columns[0].DATA_TYPE, 23);
  assert.equal(columns[0].TYPE_NAME, "int4");
  assert.equal(columns[0].ORDINAL_POSITION, 1);
  assert.equal(columns[0].IS_NULLABLE, "NO");
});

test("filterMetadataRowsByRestrictions supports aliases, null matching, and unknown-key ignore", () => {
  const rows = [
    { schema_name: "sys", table_name: "events", owner_id: null },
    { schema_name: "users", table_name: "events", owner_id: null },
    { schema_name: "users", table_name: "profiles", owner_id: 7 },
  ];

  let filtered = filterMetadataRowsByRestrictions(rows, { schema: "users", table: "events" }, "tables");
  assert.deepEqual(filtered, [{ schema_name: "users", table_name: "events", owner_id: null }]);

  filtered = filterMetadataRowsByRestrictions(rows, { owner_id: "null", missing_filter: "ignored" }, "tables");
  assert.equal(filtered.length, 2);
  assert.equal(filtered[0].schema_name, "sys");
  assert.equal(filtered[1].schema_name, "users");
});

test("getSchema returns synthetic catalogs without issuing SQL", async () => {
  const client = new Client({ user: "me", database: "main" });
  client.connected = true;
  let queryInvoked = false;
  client.query = async () => {
    queryInvoked = true;
    return { rows: [], rowCount: 0, fields: [], command: "SELECT", lastId: null };
  };

  const catalogs = await client.getSchema("catalogs");
  assert.equal(queryInvoked, false);
  assert.equal(catalogs.rowCount, 1);
  assert.equal(catalogs.rows[0].catalog_name, "main");
  assert.equal(catalogs.rows[0].TABLE_CAT, "main");
  assert.equal(catalogs.rows[0].table_catalog, "main");
});

test("getSchema applies restrictions before schema parent expansion", async () => {
  const client = new Client({ user: "me", database: "db", metadataExpandSchemaParents: true });
  client.connected = true;
  client.query = async () => ({
    rows: [
      { schema_name: "users.alice.dev" },
      { schema_name: "sys.admin" },
    ],
    rowCount: 2,
    fields: [],
    command: "SELECT",
    lastId: null,
  });

  const schemas = await client.getSchema("schemas", { schema_name: "users.alice.dev" });
  assert.deepEqual(
    schemas.rows.map((row) => row.schema_name),
    ["users", "users.alice", "users.alice.dev"],
  );
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

test("mapSqlState resolves typed driver errors for known classes", () => {
  assert.equal(mapSqlState("42P01"), ScratchbirdSyntaxError);
  assert.equal(mapSqlState("08006"), ScratchbirdConnectionError);
  assert.equal(mapSqlState("08ZZZ"), ScratchbirdConnectionError);
  assert.equal(mapSqlState("22ZZZ"), ScratchbirdDataError);
  assert.equal(mapSqlState("99999"), ScratchbirdError);
  assert.equal(mapSqlState(undefined), ScratchbirdError);
});

test("pool query returns leased clients and releases them to idle queue", async () => {
  const originalConnect = Client.prototype.connect;
  const originalQuery = Client.prototype.query;
  const originalEnd = Client.prototype.end;
  try {
    let connects = 0;
    let ends = 0;
    Client.prototype.connect = async function mockConnect() {
      this.connected = true;
      connects++;
    };
    Client.prototype.query = async function mockQuery() {
      return { rows: [{ ok: 1 }], rowCount: 1, fields: [], command: "SELECT", lastId: null };
    };
    Client.prototype.end = async function mockEnd() {
      this.connected = false;
      ends++;
    };

    const pool = new Pool({ user: "me", database: "db", max: 1, idleTimeoutMs: 5 });
    const first = await pool.query("select 1");
    const second = await pool.query("select 1");
    assert.equal(first.rows[0].ok, 1);
    assert.equal(second.rows[0].ok, 1);
    assert.equal(connects, 1, "expected pooled client reuse");

    await new Promise((resolve) => setTimeout(resolve, 10));
    await pool.query("select 1");
    await pool.end();
    assert.ok(ends >= 1);
  } finally {
    Client.prototype.connect = originalConnect;
    Client.prototype.query = originalQuery;
    Client.prototype.end = originalEnd;
  }
});

test("circuit breaker transitions through open and half-open gates", () => {
  const originalNow = Date.now;
  let now = 1_000;
  Date.now = () => now;
  try {
    const breaker = new CircuitBreaker({
      failureThreshold: 2,
      recoveryTimeoutMs: 50,
      successThreshold: 2,
      halfOpenMaxRequests: 2,
    }, "node-unit");

    assert.equal(breaker.getState(), "CLOSED");
    breaker.recordFailure();
    assert.equal(breaker.getState(), "CLOSED");
    breaker.recordFailure();
    assert.equal(breaker.getState(), "OPEN");
    assert.equal(breaker.allowRequest(), false);

    now += 75;
    assert.equal(breaker.allowRequest(), true);
    assert.equal(breaker.getState(), "HALF_OPEN");
    assert.equal(breaker.allowRequest(), true);
    assert.equal(breaker.allowRequest(), false, "half-open request cap should be enforced");

    breaker.recordSuccess();
    assert.equal(breaker.getState(), "HALF_OPEN");
    breaker.recordSuccess();
    assert.equal(breaker.getState(), "CLOSED");
  } finally {
    Date.now = originalNow;
  }
});

test("keepalive manager validates idle trackers and keeps unhealthy trackers stale", async () => {
  const originalNow = Date.now;
  let now = 0;
  Date.now = () => now;
  try {
    const manager = new KeepaliveManager({
      intervalMs: 1_000,
      maxIdleBeforeCheckMs: 10,
      validationTimeoutMs: 10,
    });
    let healthyPings = 0;
    let unhealthyPings = 0;

    const healthy = manager.register("healthy", async () => {
      healthyPings += 1;
      return true;
    });
    const unhealthy = manager.register("unhealthy", async () => {
      unhealthyPings += 1;
      return false;
    });

    now = 11;
    await manager.checkConnections();
    assert.equal(healthyPings, 1);
    assert.equal(unhealthyPings, 1);
    assert.equal(healthy.needsValidation(), false, "healthy tracker should be refreshed");
    assert.equal(unhealthy.needsValidation(), true, "unhealthy tracker should remain stale");

    manager.unregister("healthy");
    now = 25;
    await manager.checkConnections();
    assert.equal(healthyPings, 1, "unregistered tracker should not be pinged");
    assert.equal(unhealthyPings, 2);
  } finally {
    Date.now = originalNow;
  }
});

test("leak detector reports potential leaks and guard release is idempotent", () => {
  const originalNow = Date.now;
  let now = 5_000;
  Date.now = () => now;
  try {
    const detector = new LeakDetector({ thresholdMs: 20, captureStackTrace: true, checkIntervalMs: 100 });
    const guard = detector.checkout("conn-1", { lane: "node" });

    assert.equal(detector.activeCount(), 1);
    assert.equal(detector.stats().potentialLeaks, 0);

    const checkoutInfo = detector.checkouts.get("conn-1");
    assert.ok(checkoutInfo?.stackTrace, "stack trace should be captured when enabled");

    now += 25;
    assert.equal(detector.stats().potentialLeaks, 1);

    guard.release();
    guard.release();
    assert.equal(detector.activeCount(), 0);
  } finally {
    Date.now = originalNow;
  }
});

test("telemetry collector tracks metrics and slow query attributes", () => {
  const originalNow = Date.now;
  let now = 10_000;
  Date.now = () => now;
  try {
    const collector = new TelemetryCollector({ slowQueryThresholdMs: 50 });
    const span = collector.startSpan("query");
    assert.ok(span);

    span.withAttribute(
      "db.statement",
      TelemetryCollector.sanitizeQuery("select * from t where api_key = 'secret'"),
    );

    now += 60;
    collector.endSpan(span, false);

    const metrics = collector.metrics();
    assert.equal(metrics.totalQueries, 1);
    assert.equal(metrics.failedQueries, 1);
    assert.equal(metrics.successfulQueries, 0);
    assert.equal(metrics.operationMetrics.query.count, 1);
    assert.equal(metrics.operationMetrics.query.errorCount, 1);

    const slowQueries = collector.slowQueryLog();
    assert.equal(slowQueries.length, 1);
    assert.equal(slowQueries[0].spanName, "query");
    assert.equal(slowQueries[0].attributes["db.statement"], "select * from t where api_key = '?'");

    const prometheus = collector.exportPrometheusMetrics();
    assert.match(prometheus, /scratchbird_queries_total 1/);
  } finally {
    Date.now = originalNow;
  }
});
