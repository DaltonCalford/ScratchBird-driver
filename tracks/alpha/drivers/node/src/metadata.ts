// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

export const METADATA_SCHEMAS_QUERY =
  "SELECT schema_id, schema_name, owner_id, default_tablespace_id FROM sys.schemas WHERE is_valid = 1 ORDER BY schema_name";

export const METADATA_CATALOGS_QUERY =
  "SELECT schema_id AS catalog_id, schema_name AS catalog_name FROM sys.schemas WHERE is_valid = 1 ORDER BY schema_name";

export const METADATA_TABLES_QUERY =
  "SELECT table_id, schema_id, table_name, table_type, owner_id FROM sys.tables WHERE is_valid = 1 ORDER BY table_name";

export const METADATA_COLUMNS_QUERY =
  "SELECT column_id, table_id, column_name, data_type_id, data_type_name, ordinal_position, is_nullable, default_value, domain_id, collation_id, charset_id, is_identity, is_generated, generation_expression FROM sys.columns WHERE is_valid = 1 ORDER BY table_id, ordinal_position";

export const METADATA_INDEXES_QUERY =
  "SELECT index_id, table_id, index_name, index_type, is_unique FROM sys.indexes WHERE is_valid = 1 ORDER BY table_id, index_name";

export const METADATA_INDEX_COLUMNS_QUERY =
  "SELECT index_id, column_id, column_name, ordinal_position, is_included FROM sys.index_columns ORDER BY index_id, ordinal_position";

export const METADATA_CONSTRAINTS_QUERY =
  "SELECT constraint_id, table_id, constraint_name, constraint_type FROM sys.constraints WHERE is_valid = 1 ORDER BY table_id, constraint_name";

export const METADATA_PRIMARY_KEYS_QUERY =
  "SELECT constraint_id, table_id, constraint_name, constraint_type FROM sys.constraints WHERE is_valid = 1 AND lower(constraint_type) IN ('primary key', 'primary') ORDER BY table_id, constraint_name";

export const METADATA_FOREIGN_KEYS_QUERY =
  "SELECT constraint_id, table_id, constraint_name, constraint_type FROM sys.constraints WHERE is_valid = 1 AND lower(constraint_type) IN ('foreign key', 'foreign') ORDER BY table_id, constraint_name";

export const METADATA_TABLE_PRIVILEGES_QUERY =
  "SELECT table_id, table_name, owner_id AS grantor_id, owner_id AS grantee_id, 'ALL' AS privilege_type FROM sys.tables WHERE is_valid = 1 ORDER BY table_id, table_name";

export const METADATA_COLUMN_PRIVILEGES_QUERY =
  "SELECT table_id, column_id, column_name, 'ALL' AS privilege_type FROM sys.columns WHERE is_valid = 1 ORDER BY table_id, ordinal_position";

export const METADATA_PROCEDURES_QUERY =
  "SELECT procedure_id, schema_id, procedure_name, routine_type FROM sys.procedures WHERE is_valid = 1 ORDER BY schema_id, procedure_name";

export const METADATA_FUNCTIONS_QUERY =
  "SELECT function_id, schema_id, function_name FROM sys.functions WHERE is_valid = 1 ORDER BY schema_id, function_name";

export const METADATA_TYPE_INFO_QUERY =
  "SELECT DISTINCT data_type_id, data_type_name FROM sys.columns WHERE is_valid = 1 ORDER BY data_type_name";

export type MetadataCollectionName =
  | "catalogs"
  | "schemas"
  | "tables"
  | "columns"
  | "indexes"
  | "index_columns"
  | "constraints"
  | "primary_keys"
  | "foreign_keys"
  | "table_privileges"
  | "column_privileges"
  | "procedures"
  | "functions"
  | "type_info";

export interface MetadataSchemaTreeNode {
  name: string;
  path: string;
  terminal: boolean;
  children: MetadataSchemaTreeNode[];
}

export interface MetadataSchemaTree {
  database: string | null;
  schemas: MetadataSchemaTreeNode[];
}

export interface MetadataSchemaTreeOptions {
  expandParents?: boolean;
  database?: string;
  restrictions?: MetadataRestrictions;
}

export type MetadataSchemaInput = string | Record<string, unknown>;
export type MetadataRestrictions = Record<string, unknown>;

const METADATA_COLLECTION_QUERIES: Record<MetadataCollectionName, string> = {
  catalogs: METADATA_CATALOGS_QUERY,
  schemas: METADATA_SCHEMAS_QUERY,
  tables: METADATA_TABLES_QUERY,
  columns: METADATA_COLUMNS_QUERY,
  indexes: METADATA_INDEXES_QUERY,
  index_columns: METADATA_INDEX_COLUMNS_QUERY,
  constraints: METADATA_CONSTRAINTS_QUERY,
  primary_keys: METADATA_PRIMARY_KEYS_QUERY,
  foreign_keys: METADATA_FOREIGN_KEYS_QUERY,
  table_privileges: METADATA_TABLE_PRIVILEGES_QUERY,
  column_privileges: METADATA_COLUMN_PRIVILEGES_QUERY,
  procedures: METADATA_PROCEDURES_QUERY,
  functions: METADATA_FUNCTIONS_QUERY,
  type_info: METADATA_TYPE_INFO_QUERY,
};

const METADATA_COLLECTION_ALIASES: Record<string, MetadataCollectionName> = {
  catalogs: "catalogs",
  catalog: "catalogs",
  schemas: "schemas",
  schema: "schemas",
  tables: "tables",
  table: "tables",
  columns: "columns",
  column: "columns",
  indexes: "indexes",
  index: "indexes",
  indexcolumns: "index_columns",
  index_columns: "index_columns",
  constraints: "constraints",
  constraint: "constraints",
  primarykeys: "primary_keys",
  primary_keys: "primary_keys",
  primarykey: "primary_keys",
  pk: "primary_keys",
  foreignkeys: "foreign_keys",
  foreign_keys: "foreign_keys",
  foreignkey: "foreign_keys",
  fk: "foreign_keys",
  tableprivileges: "table_privileges",
  table_privileges: "table_privileges",
  columnprivileges: "column_privileges",
  column_privileges: "column_privileges",
  procedures: "procedures",
  procedure: "procedures",
  functions: "functions",
  function: "functions",
  typeinfo: "type_info",
  type_info: "type_info",
  types: "type_info",
};

const SCHEMA_FIELD_CANDIDATES = [
  "schema_name",
  "TABLE_SCHEM",
  "table_schem",
  "table_schema",
  "TABLE_SCHEMA",
  "schema",
] as const;

const METADATA_RESTRICTION_KEY_ALIASES: Record<string, readonly string[]> = {
  catalog: ["catalog_name", "table_catalog", "table_cat", "catalog"],
  schema: ["schema_name", "table_schema", "table_schem", "schema"],
  table: ["table_name", "table", "relname"],
  column: ["column_name", "column"],
  index: ["index_name", "index"],
  constraint: ["constraint_name", "constraint"],
  procedure: ["procedure_name", "routine_name", "procedure"],
  function: ["function_name", "routine_name", "function"],
  type: ["type_name", "data_type_name", "data_type", "udt_name"],
};

const METADATA_COLLECTION_RESTRICTION_KEYS: Record<MetadataCollectionName, readonly string[]> = {
  catalogs: ["catalog"],
  schemas: ["catalog", "schema"],
  tables: ["catalog", "schema", "table", "type"],
  columns: ["catalog", "schema", "table", "column", "type"],
  indexes: ["catalog", "schema", "table", "index"],
  index_columns: ["catalog", "schema", "table", "index", "column"],
  constraints: ["catalog", "schema", "table", "constraint"],
  primary_keys: ["catalog", "schema", "table", "constraint"],
  foreign_keys: ["catalog", "schema", "table", "constraint"],
  table_privileges: ["catalog", "schema", "table"],
  column_privileges: ["catalog", "schema", "table", "column"],
  procedures: ["catalog", "schema", "procedure"],
  functions: ["catalog", "schema", "function"],
  type_info: ["type"],
};

export function normalizeMetadataCollectionName(collectionName?: string): MetadataCollectionName {
  const normalized = (collectionName ?? "tables").trim().toLowerCase();
  const resolved = METADATA_COLLECTION_ALIASES[normalized];
  if (resolved) {
    return resolved;
  }
  throw new Error(`Metadata collection '${collectionName ?? ""}' is not supported`);
}

export function resolveMetadataCollectionQuery(collectionName?: string): string {
  return METADATA_COLLECTION_QUERIES[normalizeMetadataCollectionName(collectionName)];
}

export function normalizeMetadataRestrictions(restrictions?: MetadataRestrictions): MetadataRestrictions {
  if (!restrictions) {
    return {};
  }
  const out: MetadataRestrictions = {};
  for (const [key, value] of Object.entries(restrictions)) {
    const normalizedKey = normalizeMetadataIdentifier(key);
    if (!normalizedKey) {
      continue;
    }
    out[normalizedKey] = value;
  }
  return out;
}

export function filterMetadataRowsByRestrictions<T extends Record<string, unknown>>(
  rows: readonly T[],
  restrictions?: MetadataRestrictions,
  collectionName?: string,
): T[] {
  const normalizedRestrictions = normalizeMetadataRestrictions(restrictions);
  if (Object.keys(normalizedRestrictions).length === 0) {
    return [...rows];
  }
  const bindings = buildMetadataRestrictionBindings(rows, normalizedRestrictions, collectionName);
  if (!bindings.length) {
    return [...rows];
  }
  return rows.filter((row) => metadataRowMatchesBindings(row, bindings));
}

export function expandSchemaPaths(schemaPaths: readonly string[]): string[] {
  const out: string[] = [];
  const seen = new Set<string>();
  for (const schemaPath of schemaPaths) {
    const segments = splitSchemaPath(schemaPath);
    if (!segments.length) {
      continue;
    }
    let current = "";
    for (const segment of segments) {
      current = current ? `${current}.${segment}` : segment;
      if (!seen.has(current)) {
        seen.add(current);
        out.push(current);
      }
    }
  }
  return out;
}

export function listMetadataSchemaPaths(rows: readonly MetadataSchemaInput[], options?: { expandParents?: boolean }): string[] {
  const deduped: string[] = [];
  const seen = new Set<string>();
  for (const row of rows) {
    const schemaPath = readSchemaPath(row);
    if (!schemaPath || seen.has(schemaPath)) {
      continue;
    }
    seen.add(schemaPath);
    deduped.push(schemaPath);
  }
  return options?.expandParents ? expandSchemaPaths(deduped) : deduped;
}

export function buildMetadataSchemaTree(rows: readonly MetadataSchemaInput[], options?: MetadataSchemaTreeOptions): MetadataSchemaTree {
  const basePaths = listMetadataSchemaPaths(rows);
  const expandedPaths = options?.expandParents ? expandSchemaPaths(basePaths) : basePaths;
  const terminalPaths = new Set(options?.expandParents ? expandedPaths : basePaths);
  const nodesByPath = new Map<string, MetadataSchemaTreeNode>();
  const roots: MetadataSchemaTreeNode[] = [];

  for (const schemaPath of expandedPaths) {
    let parent: MetadataSchemaTreeNode | null = null;
    let currentPath = "";
    for (const segment of splitSchemaPath(schemaPath)) {
      currentPath = currentPath ? `${currentPath}.${segment}` : segment;
      let node = nodesByPath.get(currentPath);
      if (!node) {
        node = { name: segment, path: currentPath, terminal: false, children: [] };
        nodesByPath.set(currentPath, node);
        if (parent) {
          parent.children.push(node);
        } else {
          roots.push(node);
        }
      }
      if (terminalPaths.has(currentPath)) {
        node.terminal = true;
      }
      parent = node;
    }
  }

  const database = options?.database?.trim();
  return {
    database: database ? database : null,
    schemas: roots,
  };
}

export function expandSchemaMetadataRows<T extends Record<string, unknown>>(rows: readonly T[]): T[] {
  const out: T[] = [];
  const seen = new Set<string>();
  for (const row of rows) {
    const schemaPath = readSchemaPath(row);
    if (!schemaPath) {
      out.push(row);
      continue;
    }
    let current = "";
    const segments = splitSchemaPath(schemaPath);
    for (let i = 0; i < segments.length; i++) {
      current = current ? `${current}.${segments[i]}` : segments[i];
      if (seen.has(current)) {
        continue;
      }
      seen.add(current);
      if (i === segments.length - 1) {
        out.push(row);
      } else {
        out.push(createSyntheticSchemaRow(row, current));
      }
    }
  }
  return out;
}

interface MetadataRestrictionBinding {
  aliases: string[];
  expectNull: boolean;
  expectedText: string;
}

function buildMetadataRestrictionBindings(
  rows: readonly Record<string, unknown>[],
  restrictions: MetadataRestrictions,
  collectionName?: string,
): MetadataRestrictionBinding[] {
  const allowedAliases = new Set<string>();
  if (collectionName) {
    const resolvedCollection = normalizeMetadataCollectionName(collectionName);
    for (const restrictionKey of METADATA_COLLECTION_RESTRICTION_KEYS[resolvedCollection]) {
      for (const alias of metadataRestrictionAliases(restrictionKey)) {
        allowedAliases.add(alias);
      }
    }
  }

  const bindings: MetadataRestrictionBinding[] = [];
  for (const [restrictionKey, restrictionValue] of Object.entries(restrictions)) {
    const aliases = new Set<string>();
    for (const alias of metadataRestrictionAliases(restrictionKey)) {
      if (allowedAliases.size > 0 && !allowedAliases.has(alias) && alias !== restrictionKey) {
        continue;
      }
      aliases.add(alias);
    }
    if (!aliases.size) {
      continue;
    }
    if (!rowsHaveAnyAlias(rows, aliases)) {
      continue;
    }

    const expectedText = normalizeMetadataMatchText(restrictionValue);
    bindings.push({
      aliases: [...aliases],
      expectNull: expectedText === "null",
      expectedText,
    });
  }
  return bindings;
}

function rowsHaveAnyAlias(rows: readonly Record<string, unknown>[], aliases: Set<string>): boolean {
  for (const row of rows) {
    for (const alias of aliases) {
      if (metadataRowValueByAlias(row, alias).present) {
        return true;
      }
    }
  }
  return false;
}

function metadataRowMatchesBindings(row: Record<string, unknown>, bindings: readonly MetadataRestrictionBinding[]): boolean {
  for (const binding of bindings) {
    let matched = false;
    for (const alias of binding.aliases) {
      const candidate = metadataRowValueByAlias(row, alias);
      if (!candidate.present) {
        continue;
      }
      if (binding.expectNull) {
        if (candidate.value === null) {
          matched = true;
          break;
        }
        continue;
      }
      if (candidate.value !== null && normalizeMetadataMatchText(candidate.value) === binding.expectedText) {
        matched = true;
        break;
      }
    }
    if (!matched) {
      return false;
    }
  }
  return true;
}

function metadataRowValueByAlias(
  row: Record<string, unknown>,
  alias: string,
): { present: boolean; value: unknown } {
  if (Object.prototype.hasOwnProperty.call(row, alias)) {
    return { present: true, value: row[alias] };
  }

  const target = normalizeMetadataIdentifier(alias);
  for (const [key, value] of Object.entries(row)) {
    if (normalizeMetadataIdentifier(key) === target) {
      return { present: true, value };
    }
  }
  return { present: false, value: null };
}

function metadataRestrictionAliases(key: string): string[] {
  const canonical = normalizeMetadataIdentifier(key);
  const aliases = METADATA_RESTRICTION_KEY_ALIASES[canonical] ?? [];
  return [...new Set([...aliases, canonical].map((alias) => normalizeMetadataIdentifier(alias)).filter(Boolean))];
}

function normalizeMetadataIdentifier(value: string): string {
  return value.trim().toLowerCase().replace(/[^a-z0-9]/g, "");
}

function normalizeMetadataMatchText(value: unknown): string {
  return String(value).trim().toLowerCase();
}

function splitSchemaPath(value: string): string[] {
  return value
    .split(".")
    .map((segment) => segment.trim())
    .filter((segment) => segment.length > 0);
}

function readSchemaPath(row: MetadataSchemaInput): string | null {
  if (typeof row === "string") {
    return normalizeSchemaPath(row);
  }
  for (const candidate of SCHEMA_FIELD_CANDIDATES) {
    const value = row[candidate];
    if (typeof value === "string") {
      return normalizeSchemaPath(value);
    }
  }
  return null;
}

function normalizeSchemaPath(value: string): string | null {
  const normalized = splitSchemaPath(value).join(".");
  return normalized.length ? normalized : null;
}

function createSyntheticSchemaRow<T extends Record<string, unknown>>(sample: T, schemaPath: string): T {
  const synthetic: Record<string, unknown> = {};
  for (const key of Object.keys(sample)) {
    synthetic[key] = null;
  }
  let assigned = false;
  for (const key of SCHEMA_FIELD_CANDIDATES) {
    if (key in synthetic) {
      synthetic[key] = schemaPath;
      assigned = true;
    }
  }
  if (!assigned) {
    synthetic.schema_name = schemaPath;
  }
  return synthetic as T;
}
