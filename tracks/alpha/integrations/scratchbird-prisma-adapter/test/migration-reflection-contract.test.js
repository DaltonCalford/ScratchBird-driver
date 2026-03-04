"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");

const {
  generatePrismaSchemaFromMetadata,
  buildDeterministicMigrationPlan,
  runReflectionRoundTripContract,
} = require("../lib/index");

test("buildDeterministicMigrationPlan is stable for same schema", () => {
  const schema = generatePrismaSchemaFromMetadata({
    database: "main",
    tables: [{ schema_name: "sys", table_name: "users" }],
    columns: [
      {
        table_name: "users",
        column_name: "id",
        data_type_name: "INTEGER",
        is_nullable: 0,
        is_identity: 1,
        ordinal_position: 1,
      },
    ],
  });

  const planA = buildDeterministicMigrationPlan(schema, "baseline");
  const planB = buildDeterministicMigrationPlan(schema, "baseline");

  assert.equal(planA.migrationName, planB.migrationName);
  assert.equal(planA.migrationFile, planB.migrationFile);
  assert.match(planA.sqlTemplate, /ScratchBird Prisma migration contract template/);
});

test("buildDeterministicMigrationPlan normalizes migration names", () => {
  const schema = `
    datasource db {
      provider = "scratchbird"
      url      = env("DATABASE_URL")
    }

    generator client {
      provider = "prisma-client-js"
    }

    model Demo {
      id Int @id
    }
  `;

  const plan = buildDeterministicMigrationPlan(schema, "my first migration!");
  assert.match(plan.migrationName, /^my_first_migration__?[a-f0-9]{12}$/);
});

test("runReflectionRoundTripContract returns schema summary", () => {
  const result = runReflectionRoundTripContract({
    database: "main",
    tables: [
      { schema_name: "sys", table_name: "users" },
      { schema_name: "sys", table_name: "posts" },
    ],
    columns: [
      {
        table_name: "users",
        column_name: "id",
        data_type_name: "INTEGER",
        is_nullable: 0,
        is_identity: 1,
        ordinal_position: 1,
      },
      {
        table_name: "posts",
        column_name: "id",
        data_type_name: "INTEGER",
        is_nullable: 0,
        is_identity: 1,
        ordinal_position: 1,
      },
    ],
  });

  assert.equal(result.modelCount, 2);
  assert.match(result.schemaText, /model SysUsers/);
  assert.match(result.schemaText, /model SysPosts/);
  assert.equal(result.checksum.length, 12);
});
