"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");
const adapter = require("../lib/index");

test("guardrails reject unsupported options", () => {
  assert.throws(
    () =>
      adapter.normalizeTypeOrmOptions({
        url: "scratchbird://localhost:3092/main?sslmode=disable",
      }),
    /sslmode=disable is not supported/
  );

  assert.throws(
    () =>
      adapter.normalizeTypeOrmOptions({
        url: "scratchbird://localhost:3092/main?binaryTransfer=false",
      }),
    /binaryTransfer=false is not supported/
  );

  assert.throws(
    () =>
      adapter.normalizeTypeOrmOptions({
        url: "scratchbird://localhost:3092/main?compression=zstd",
      }),
    /compression=zstd is not supported/
  );
});

test("options normalize URL fields and extra parameters", () => {
  const options = adapter.normalizeTypeOrmOptions({
    url: "scratchbird://alice:pw@db.internal:3199/maindb?sslmode=require&binaryTransfer=true",
    extra: {
      connectTimeout: "30",
    },
  });

  assert.equal(options.type, "scratchbird");
  assert.equal(options.host, "db.internal");
  assert.equal(options.port, 3199);
  assert.equal(options.database, "maindb");
  assert.equal(options.username, "alice");
  assert.equal(options.extra.sslmode, "require");
  assert.equal(options.extra.binaryTransfer, "true");
  assert.equal(options.extra.connectTimeout, "30");
});

test("type map supports scalar, array, and unknown fallback", () => {
  assert.deepEqual(adapter.mapScratchBirdTypeToTypeOrm("jsonb"), {
    typeormType: "jsonb",
    unsupported: false,
    isArray: false,
  });

  assert.deepEqual(adapter.mapScratchBirdTypeToTypeOrm("varchar[]"), {
    typeormType: "varchar",
    unsupported: false,
    isArray: true,
  });

  assert.deepEqual(adapter.mapScratchBirdTypeToTypeOrm("mystery_type"), {
    typeormType: "varchar",
    unsupported: true,
    isArray: false,
  });
});

test("metadata catalog generates entity schemas with nested relation", () => {
  const schemas = adapter.generateEntitySchemas({
    schemas: [
      {
        name: "sys",
        tables: [
          {
            name: "users",
            columns: [
              { name: "id", type: "bigint", nullable: false, identity: true },
              { name: "name", type: "varchar", nullable: false },
            ],
            primaryKey: ["id"],
          },
          {
            name: "posts",
            columns: [
              { name: "id", type: "bigint", nullable: false, identity: true },
              { name: "user_id", type: "bigint", nullable: false },
            ],
            primaryKey: ["id"],
            relations: [
              {
                name: "user",
                type: "many-to-one",
                targetSchema: "sys",
                targetTable: "users",
                joinColumn: "user_id",
                referencedColumn: "id",
              },
            ],
          },
        ],
      },
    ],
  });

  assert.equal(schemas.length, 2);

  const posts = schemas.find((schema) => schema.name === "sys_posts");
  assert.ok(posts);
  assert.equal(posts.columns.id.generated, "increment");
  assert.equal(posts.columns.id.primary, true);
  assert.equal(posts.relations.user.target, "sys_users");
  assert.equal(posts.relations.user.joinColumn.name, "user_id");
});

test("nested CRUD transaction plan includes savepoint lifecycle", () => {
  const plan = adapter.buildNestedCrudTransactionPlan({
    parentTable: "users",
    childTable: "posts",
    parentKey: "id",
    childFk: "user_id",
  });

  assert.deepEqual(plan.slice(0, 3), [
    "BEGIN",
    "INSERT INTO users (id) VALUES (:parent_id)",
    "SAVEPOINT after_parent_insert",
  ]);
  assert.equal(plan.at(-1), "COMMIT");
  assert.ok(plan.includes("ROLLBACK TO SAVEPOINT after_parent_insert"));
});
