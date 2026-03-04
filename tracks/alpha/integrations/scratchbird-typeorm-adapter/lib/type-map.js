"use strict";

const BASE_TYPE_MAP = {
  BOOLEAN: { typeormType: "boolean" },
  SMALLINT: { typeormType: "smallint" },
  INTEGER: { typeormType: "int" },
  INT: { typeormType: "int" },
  BIGINT: { typeormType: "bigint" },
  REAL: { typeormType: "float" },
  FLOAT: { typeormType: "float" },
  "DOUBLE PRECISION": { typeormType: "double precision" },
  NUMERIC: { typeormType: "numeric" },
  DECIMAL: { typeormType: "decimal" },
  CHAR: { typeormType: "char" },
  VARCHAR: { typeormType: "varchar" },
  "CHARACTER VARYING": { typeormType: "varchar" },
  TEXT: { typeormType: "text" },
  DATE: { typeormType: "date" },
  TIME: { typeormType: "time" },
  TIMESTAMP: { typeormType: "timestamp" },
  TIMESTAMPTZ: { typeormType: "timestamptz" },
  UUID: { typeormType: "uuid" },
  JSON: { typeormType: "json" },
  JSONB: { typeormType: "jsonb" },
  BYTEA: { typeormType: "bytea" },
  BLOB: { typeormType: "bytea" },
  VECTOR: { typeormType: "text", unsupported: true },
  GEOMETRY: { typeormType: "bytea", unsupported: true },
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

function mapScratchBirdTypeToTypeOrm(typeName) {
  const normalized = normalizeTypeName(typeName);
  const isArray = normalized.endsWith("[]");
  const base = isArray ? normalized.slice(0, -2) : normalized;
  const mapped = BASE_TYPE_MAP[base] || { typeormType: "varchar", unsupported: true };

  return {
    typeormType: mapped.typeormType,
    unsupported: Boolean(mapped.unsupported),
    isArray,
  };
}

module.exports = {
  normalizeTypeName,
  mapScratchBirdTypeToTypeOrm,
};
