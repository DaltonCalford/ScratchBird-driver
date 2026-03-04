"use strict";

const {
  runReflectionRoundTripContract,
  buildDeterministicMigrationPlan,
} = require("../lib/index");

const metadataInput = {
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
};

const reflection = runReflectionRoundTripContract(metadataInput);
const migrationPlan = buildDeterministicMigrationPlan(reflection.schemaText, "baseline");

console.log(JSON.stringify({ reflection, migrationPlan }, null, 2));
