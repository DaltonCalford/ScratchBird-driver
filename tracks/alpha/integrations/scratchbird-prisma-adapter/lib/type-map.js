"use strict";

const BASE_TYPE_MAP = {
  BOOLEAN: { prismaType: "Boolean" },
  SMALLINT: { prismaType: "Int" },
  INTEGER: { prismaType: "Int" },
  INT: { prismaType: "Int" },
  BIGINT: { prismaType: "BigInt" },
  REAL: { prismaType: "Float" },
  FLOAT: { prismaType: "Float" },
  "DOUBLE PRECISION": { prismaType: "Float" },
  NUMERIC: { prismaType: "Decimal" },
  DECIMAL: { prismaType: "Decimal" },
  VARCHAR: { prismaType: "String" },
  "CHARACTER VARYING": { prismaType: "String" },
  TEXT: { prismaType: "String" },
  UUID: { prismaType: "String", nativeType: "Uuid" },
  JSON: { prismaType: "Json" },
  JSONB: { prismaType: "Json" },
  BYTEA: { prismaType: "Bytes" },
  DATE: { prismaType: "DateTime", nativeType: "Date" },
  TIMESTAMP: { prismaType: "DateTime", nativeType: "Timestamp" },
  TIMESTAMPTZ: { prismaType: "DateTime", nativeType: "Timestamptz" },
  "TIMESTAMP WITH TIME ZONE": { prismaType: "DateTime", nativeType: "Timestamptz" },
  "TIMESTAMP WITHOUT TIME ZONE": { prismaType: "DateTime", nativeType: "Timestamp" },
};

function normalizeTypeName(typeName) {
  if (!typeName) {
    return "";
  }
  let normalized = String(typeName).trim().toUpperCase();
  normalized = normalized.replace(/\s+/g, " ");
  const parenIndex = normalized.indexOf("(");
  if (parenIndex >= 0) {
    normalized = normalized.slice(0, parenIndex).trim();
  }
  return normalized;
}

function mapScratchBirdTypeToPrisma(typeName) {
  const normalized = normalizeTypeName(typeName);
  const isArray = normalized.endsWith("[]");
  const base = isArray ? normalized.slice(0, -2) : normalized;

  const mapped = BASE_TYPE_MAP[base] || { prismaType: "String", unsupported: true };
  return {
    prismaType: mapped.prismaType,
    nativeType: mapped.nativeType,
    unsupported: Boolean(mapped.unsupported),
    isArray,
  };
}

function isPrismaSupportedScratchBirdType(typeName) {
  return !mapScratchBirdTypeToPrisma(typeName).unsupported;
}

module.exports = {
  normalizeTypeName,
  mapScratchBirdTypeToPrisma,
  isPrismaSupportedScratchBirdType,
};
