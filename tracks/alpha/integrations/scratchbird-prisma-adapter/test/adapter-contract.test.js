"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");

const {
  parseScratchbirdConnectionUrl,
  validatePrismaSchemaText,
  mapScratchBirdTypeToPrisma,
  generatePrismaSchemaFromMetadata,
} = require("../lib/index");

test("parseScratchbirdConnectionUrl accepts baseline secure URL", () => {
  const parsed = parseScratchbirdConnectionUrl(
    "scratchbird://alice:secret@db.local:3092/mydb?sslmode=require&binaryTransfer=true",
  );
  assert.equal(parsed.host, "db.local");
  assert.equal(parsed.port, 3092);
  assert.equal(parsed.database, "mydb");
  assert.equal(parsed.username, "alice");
  assert.equal(parsed.params.sslmode, "require");
});

test("parseScratchbirdConnectionUrl rejects insecure or unsupported flags", () => {
  assert.throws(
    () => parseScratchbirdConnectionUrl("scratchbird://db.local/mydb?sslmode=disable"),
    /sslmode=disable/,
  );
  assert.throws(
    () => parseScratchbirdConnectionUrl("scratchbird://db.local/mydb?binaryTransfer=false"),
    /binary_transfer=false/,
  );
  assert.throws(
    () => parseScratchbirdConnectionUrl("scratchbird://db.local/mydb?compression=zstd"),
    /compression=zstd/,
  );
});

test("validatePrismaSchemaText enforces datasource + generator + env URL", () => {
  const valid = `
    datasource db {
      provider = "scratchbird"
      url      = env("DATABASE_URL")
    }

    generator client {
      provider = "prisma-client-js"
    }
  `;
  assert.equal(validatePrismaSchemaText(valid), true);

  assert.throws(() => validatePrismaSchemaText("generator client {}"), /datasource/);
  assert.throws(() => validatePrismaSchemaText("datasource db {}"), /generator/);
});

test("mapScratchBirdTypeToPrisma handles core, json, and arrays", () => {
  assert.deepEqual(mapScratchBirdTypeToPrisma("INTEGER"), {
    prismaType: "Int",
    nativeType: undefined,
    unsupported: false,
    isArray: false,
  });
  assert.deepEqual(mapScratchBirdTypeToPrisma("jsonb"), {
    prismaType: "Json",
    nativeType: undefined,
    unsupported: false,
    isArray: false,
  });
  assert.deepEqual(mapScratchBirdTypeToPrisma("varchar[]"), {
    prismaType: "String",
    nativeType: undefined,
    unsupported: false,
    isArray: true,
  });
});

test("generatePrismaSchemaFromMetadata emits deterministic models", () => {
  const schemaText = generatePrismaSchemaFromMetadata({
    database: "main_db",
    tables: [
      { schema_name: "users", table_name: "account" },
    ],
    columns: [
      {
        table_name: "account",
        column_name: "id",
        data_type_name: "INTEGER",
        is_nullable: 0,
        is_identity: 1,
        ordinal_position: 1,
      },
      {
        table_name: "account",
        column_name: "profile",
        data_type_name: "JSONB",
        is_nullable: 1,
        ordinal_position: 2,
      },
    ],
  });

  assert.match(schemaText, /provider = "scratchbird"/);
  assert.match(schemaText, /model UsersAccount/);
  assert.match(schemaText, /id Int @id @default\(autoincrement\(\)\)/);
  assert.match(schemaText, /profile Json\?/);
  assert.match(schemaText, /@@map\("account"\)/);
});
