"use strict";

const { normalizeTypeOrmOptions, enforceGuardrails } = require("./options");
const { mapScratchBirdTypeToTypeOrm, normalizeTypeName } = require("./type-map");
const { generateEntitySchemas, buildEntityName } = require("./entity-schema");
const { buildNestedCrudTransactionPlan } = require("./transaction-contract");

module.exports = {
  normalizeTypeOrmOptions,
  enforceGuardrails,
  mapScratchBirdTypeToTypeOrm,
  normalizeTypeName,
  generateEntitySchemas,
  buildEntityName,
  buildNestedCrudTransactionPlan,
};
