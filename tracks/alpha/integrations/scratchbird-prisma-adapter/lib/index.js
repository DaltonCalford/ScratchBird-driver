"use strict";

const {
  parseScratchbirdConnectionUrl,
  validatePrismaSchemaText,
} = require("./connection-url");
const {
  normalizeTypeName,
  mapScratchBirdTypeToPrisma,
  isPrismaSupportedScratchBirdType,
} = require("./type-map");
const { generatePrismaSchemaFromMetadata } = require("./schema-generator");
const {
  buildDeterministicMigrationPlan,
  runReflectionRoundTripContract,
} = require("./workflow");

module.exports = {
  parseScratchbirdConnectionUrl,
  validatePrismaSchemaText,
  normalizeTypeName,
  mapScratchBirdTypeToPrisma,
  isPrismaSupportedScratchBirdType,
  generatePrismaSchemaFromMetadata,
  buildDeterministicMigrationPlan,
  runReflectionRoundTripContract,
};
