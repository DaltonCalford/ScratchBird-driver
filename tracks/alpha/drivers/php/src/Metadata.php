<?php
/*
 * ScratchBird-driver
 * Copyright (c) 2025-2026 Dalton Calford
 *
 * Licensed under the Initial Developer's Public License Version 1.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at:
 * https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
 */

namespace ScratchBird\PDO;

final class Metadata
{
    private const DEFAULT_COLLECTION = 'tables';

    private const SCHEMA_FIELD_CANDIDATES = [
        'schema_name',
        'TABLE_SCHEM',
        'table_schem',
        'table_schema',
        'TABLE_SCHEMA',
        'schema',
    ];

    public const SCHEMAS_QUERY = "SELECT schema_id, schema_name, owner_id, default_tablespace_id FROM sys.schemas WHERE is_valid = 1 ORDER BY schema_name";
    public const TABLES_QUERY = "SELECT table_id, schema_id, table_name, table_type, owner_id FROM sys.tables WHERE is_valid = 1 ORDER BY table_name";
    public const COLUMNS_QUERY = "SELECT column_id, table_id, column_name, data_type_id, data_type_name, ordinal_position, is_nullable, default_value, domain_id, collation_id, charset_id, is_identity, is_generated, generation_expression FROM sys.columns WHERE is_valid = 1 ORDER BY table_id, ordinal_position";
    public const INDEXES_QUERY = "SELECT index_id, table_id, index_name, index_type, is_unique FROM sys.indexes WHERE is_valid = 1 ORDER BY table_id, index_name";
    public const INDEX_COLUMNS_QUERY = "SELECT index_id, column_id, column_name, ordinal_position, is_included FROM sys.index_columns ORDER BY index_id, ordinal_position";
    public const CONSTRAINTS_QUERY = "SELECT constraint_id, table_id, constraint_name, constraint_type FROM sys.constraints WHERE is_valid = 1 ORDER BY table_id, constraint_name";
    public const PROCEDURES_QUERY = "SELECT procedure_id, schema_id, procedure_name, routine_type FROM sys.procedures WHERE is_valid = 1 ORDER BY schema_id, procedure_name";
    public const FUNCTIONS_QUERY = "SELECT function_id, schema_id, function_name FROM sys.functions WHERE is_valid = 1 ORDER BY schema_id, function_name";
    public const ROUTINES_QUERY = "SELECT procedure_id AS routine_id, schema_id, procedure_name AS routine_name, routine_type FROM sys.procedures WHERE is_valid = 1 UNION ALL SELECT function_id AS routine_id, schema_id, function_name AS routine_name, 'FUNCTION' AS routine_type FROM sys.functions WHERE is_valid = 1 ORDER BY schema_id, routine_name";
    public const CATALOGS_QUERY = "SELECT schema_id AS catalog_id, schema_name AS catalog_name FROM sys.schemas WHERE is_valid = 1 ORDER BY schema_name";
    public const PRIMARY_KEYS_QUERY = "SELECT constraint_id, table_id, constraint_name, constraint_type FROM sys.constraints WHERE is_valid = 1 AND lower(constraint_type) IN ('primary key', 'primary') ORDER BY table_id, constraint_name";
    public const FOREIGN_KEYS_QUERY = "SELECT constraint_id, table_id, constraint_name, constraint_type FROM sys.constraints WHERE is_valid = 1 AND lower(constraint_type) IN ('foreign key', 'foreign') ORDER BY table_id, constraint_name";
    public const TABLE_PRIVILEGES_QUERY = "SELECT table_id, table_name, owner_id AS grantor_id, owner_id AS grantee_id, 'ALL' AS privilege_type FROM sys.tables WHERE is_valid = 1 ORDER BY table_id, table_name";
    public const COLUMN_PRIVILEGES_QUERY = "SELECT table_id, column_id, column_name, 'ALL' AS privilege_type FROM sys.columns WHERE is_valid = 1 ORDER BY table_id, ordinal_position";
    public const TYPE_INFO_QUERY = "SELECT DISTINCT data_type_id, data_type_name FROM sys.columns WHERE is_valid = 1 ORDER BY data_type_name";

    private const COLLECTION_QUERY_MAP = [
        'schemas' => self::SCHEMAS_QUERY,
        'tables' => self::TABLES_QUERY,
        'columns' => self::COLUMNS_QUERY,
        'indexes' => self::INDEXES_QUERY,
        'index_columns' => self::INDEX_COLUMNS_QUERY,
        'constraints' => self::CONSTRAINTS_QUERY,
        'procedures' => self::PROCEDURES_QUERY,
        'functions' => self::FUNCTIONS_QUERY,
        'routines' => self::ROUTINES_QUERY,
        'catalogs' => self::CATALOGS_QUERY,
        'primary_keys' => self::PRIMARY_KEYS_QUERY,
        'foreign_keys' => self::FOREIGN_KEYS_QUERY,
        'table_privileges' => self::TABLE_PRIVILEGES_QUERY,
        'column_privileges' => self::COLUMN_PRIVILEGES_QUERY,
        'type_info' => self::TYPE_INFO_QUERY,
    ];

    private const COLLECTION_ALIASES = [
        'schemas' => 'schemas',
        'schema' => 'schemas',
        'tables' => 'tables',
        'table' => 'tables',
        'columns' => 'columns',
        'column' => 'columns',
        'indexes' => 'indexes',
        'index' => 'indexes',
        'index_columns' => 'index_columns',
        'indexcolumns' => 'index_columns',
        'constraints' => 'constraints',
        'constraint' => 'constraints',
        'procedures' => 'procedures',
        'procedure' => 'procedures',
        'functions' => 'functions',
        'function' => 'functions',
        'routines' => 'routines',
        'routine' => 'routines',
        'catalogs' => 'catalogs',
        'catalog' => 'catalogs',
        'primary_keys' => 'primary_keys',
        'primary_key' => 'primary_keys',
        'primarykeys' => 'primary_keys',
        'primarykey' => 'primary_keys',
        'foreign_keys' => 'foreign_keys',
        'foreign_key' => 'foreign_keys',
        'foreignkeys' => 'foreign_keys',
        'foreignkey' => 'foreign_keys',
        'table_privileges' => 'table_privileges',
        'table_privilege' => 'table_privileges',
        'tableprivileges' => 'table_privileges',
        'tableprivilege' => 'table_privileges',
        'column_privileges' => 'column_privileges',
        'column_privilege' => 'column_privileges',
        'columnprivileges' => 'column_privileges',
        'columnprivilege' => 'column_privileges',
        'type_info' => 'type_info',
        'typeinfo' => 'type_info',
    ];

    public static function normalizeCollectionName(?string $collectionName = null): string
    {
        $value = $collectionName ?? self::DEFAULT_COLLECTION;
        $normalized = strtolower(trim($value));
        $normalized = str_replace(['-', ' '], '_', $normalized);
        if ($normalized === '') {
            $normalized = self::DEFAULT_COLLECTION;
        }
        $collapsed = str_replace('_', '', $normalized);
        $resolved = self::COLLECTION_ALIASES[$normalized] ?? self::COLLECTION_ALIASES[$collapsed] ?? null;
        if ($resolved === null) {
            throw new \InvalidArgumentException("Metadata collection '{$value}' is not supported");
        }
        return $resolved;
    }

    public static function resolveCollectionQuery(?string $collectionName = null): string
    {
        $resolved = self::normalizeCollectionName($collectionName);
        return self::COLLECTION_QUERY_MAP[$resolved];
    }

    public static function schemasQuery(): string
    {
        return self::SCHEMAS_QUERY;
    }

    public static function tablesQuery(): string
    {
        return self::TABLES_QUERY;
    }

    public static function columnsQuery(): string
    {
        return self::COLUMNS_QUERY;
    }

    public static function indexesQuery(): string
    {
        return self::INDEXES_QUERY;
    }

    public static function indexColumnsQuery(): string
    {
        return self::INDEX_COLUMNS_QUERY;
    }

    public static function constraintsQuery(): string
    {
        return self::CONSTRAINTS_QUERY;
    }

    public static function proceduresQuery(): string
    {
        return self::PROCEDURES_QUERY;
    }

    public static function functionsQuery(): string
    {
        return self::FUNCTIONS_QUERY;
    }

    public static function routinesQuery(): string
    {
        return self::ROUTINES_QUERY;
    }

    public static function catalogsQuery(): string
    {
        return self::CATALOGS_QUERY;
    }

    public static function primaryKeysQuery(): string
    {
        return self::PRIMARY_KEYS_QUERY;
    }

    public static function foreignKeysQuery(): string
    {
        return self::FOREIGN_KEYS_QUERY;
    }

    public static function tablePrivilegesQuery(): string
    {
        return self::TABLE_PRIVILEGES_QUERY;
    }

    public static function columnPrivilegesQuery(): string
    {
        return self::COLUMN_PRIVILEGES_QUERY;
    }

    public static function typeInfoQuery(): string
    {
        return self::TYPE_INFO_QUERY;
    }

    /**
     * @param array<mixed> $schemaNames
     * @return array<string>
     */
    public static function schemaPathsForNavigation(array $schemaNames, bool $expandParents = false): array
    {
        $out = [];
        $seen = [];
        foreach ($schemaNames as $schemaName) {
            if (!is_string($schemaName) && !is_numeric($schemaName)) {
                continue;
            }
            $normalized = self::normalizeSchemaPath((string)$schemaName);
            if ($normalized === null || isset($seen[$normalized])) {
                continue;
            }
            $seen[$normalized] = true;
            $out[] = $normalized;
        }
        if (!$expandParents) {
            return $out;
        }
        return self::expandSchemaPaths($out);
    }

    /**
     * @param array<string> $schemaPaths
     * @return array<string>
     */
    public static function expandSchemaPaths(array $schemaPaths): array
    {
        $out = [];
        $seen = [];
        foreach ($schemaPaths as $schemaPath) {
            $segments = self::splitSchemaPath($schemaPath);
            if ($segments === []) {
                continue;
            }
            $currentPath = '';
            foreach ($segments as $segment) {
                $currentPath = $currentPath === '' ? $segment : $currentPath . '.' . $segment;
                if (isset($seen[$currentPath])) {
                    continue;
                }
                $seen[$currentPath] = true;
                $out[] = $currentPath;
            }
        }
        return $out;
    }

    /**
     * @param array<mixed> $rows
     * @return array<string>
     */
    public static function listMetadataSchemaPaths(array $rows, bool $expandParents = false): array
    {
        $deduped = [];
        $seen = [];
        foreach ($rows as $row) {
            $schemaPath = self::readSchemaPath($row);
            if ($schemaPath === null || isset($seen[$schemaPath])) {
                continue;
            }
            $seen[$schemaPath] = true;
            $deduped[] = $schemaPath;
        }
        if (!$expandParents) {
            return $deduped;
        }
        return self::expandSchemaPaths($deduped);
    }

    /**
     * @param array<mixed> $rows
     * @return array{database: ?string, schemas: array<int, array{name: string, path: string, terminal: bool, children: array}>}
     */
    public static function buildMetadataSchemaTree(array $rows, bool $expandParents = false, ?string $database = null): array
    {
        $basePaths = self::listMetadataSchemaPaths($rows, false);
        $expandedPaths = $expandParents ? self::expandSchemaPaths($basePaths) : $basePaths;
        $terminalPaths = [];
        foreach ($expandParents ? $expandedPaths : $basePaths as $terminalPath) {
            $terminalPaths[$terminalPath] = true;
        }

        $roots = [];
        foreach ($expandedPaths as $schemaPath) {
            $segments = self::splitSchemaPath($schemaPath);
            if ($segments === []) {
                continue;
            }

            $currentPath = '';
            $children = &$roots;
            foreach ($segments as $segment) {
                $currentPath = $currentPath === '' ? $segment : $currentPath . '.' . $segment;
                $node = &self::upsertSchemaTreeNode($children, $segment, $currentPath, isset($terminalPaths[$currentPath]));
                $children = &$node['children'];
                unset($node);
            }
            unset($children);
        }

        $database = $database === null ? null : trim($database);
        if ($database === '') {
            $database = null;
        }

        return [
            'database' => $database,
            'schemas' => $roots,
        ];
    }

    /**
     * @param array<mixed> $rows
     * @return array<mixed>
     */
    public static function expandSchemaMetadataRows(array $rows): array
    {
        $out = [];
        $seen = [];
        foreach ($rows as $row) {
            $schemaPath = self::readSchemaPath($row);
            if ($schemaPath === null) {
                $out[] = $row;
                continue;
            }
            $segments = self::splitSchemaPath($schemaPath);
            if ($segments === []) {
                $out[] = $row;
                continue;
            }

            $currentPath = '';
            $segmentCount = count($segments);
            foreach ($segments as $index => $segment) {
                $currentPath = $currentPath === '' ? $segment : $currentPath . '.' . $segment;
                if (isset($seen[$currentPath])) {
                    continue;
                }
                $seen[$currentPath] = true;
                if ($index === ($segmentCount - 1)) {
                    $out[] = $row;
                } else {
                    $out[] = is_array($row)
                        ? self::createSyntheticSchemaRow($row, $currentPath)
                        : ['schema_name' => $currentPath];
                }
            }
        }
        return $out;
    }

    /**
     * @param array<string, mixed> $sample
     * @return array<string, mixed>
     */
    private static function createSyntheticSchemaRow(array $sample, string $schemaPath): array
    {
        $synthetic = [];
        foreach ($sample as $key => $_value) {
            if (!is_string($key)) {
                continue;
            }
            $synthetic[$key] = null;
        }

        $assigned = false;
        foreach (self::SCHEMA_FIELD_CANDIDATES as $candidate) {
            $key = self::metadataRowKey($synthetic, $candidate);
            if ($key === null) {
                continue;
            }
            $synthetic[$key] = $schemaPath;
            $assigned = true;
        }
        if (!$assigned) {
            $synthetic['schema_name'] = $schemaPath;
        }

        return $synthetic;
    }

    /**
     * @param array<mixed> $row
     */
    private static function readSchemaPath(mixed $row): ?string
    {
        if (is_string($row) || is_numeric($row)) {
            return self::normalizeSchemaPath((string)$row);
        }
        if (!is_array($row)) {
            return null;
        }

        foreach (self::SCHEMA_FIELD_CANDIDATES as $candidate) {
            $value = self::metadataRowValue($row, $candidate);
            if (!is_string($value)) {
                continue;
            }
            $normalized = self::normalizeSchemaPath($value);
            if ($normalized !== null) {
                return $normalized;
            }
        }
        return null;
    }

    /**
     * @param array<string, mixed> $row
     */
    private static function metadataRowValue(array $row, string $key): mixed
    {
        if (array_key_exists($key, $row)) {
            return $row[$key];
        }
        foreach ($row as $candidate => $value) {
            if (!is_string($candidate)) {
                continue;
            }
            if (strcasecmp($candidate, $key) === 0) {
                return $value;
            }
        }
        return null;
    }

    /**
     * @param array<string, mixed> $row
     */
    private static function metadataRowKey(array $row, string $key): ?string
    {
        if (array_key_exists($key, $row)) {
            return $key;
        }
        foreach ($row as $candidate => $_value) {
            if (!is_string($candidate)) {
                continue;
            }
            if (strcasecmp($candidate, $key) === 0) {
                return $candidate;
            }
        }
        return null;
    }

    /**
     * @return array<string>
     */
    private static function splitSchemaPath(string $value): array
    {
        $parts = [];
        foreach (explode('.', $value) as $part) {
            $part = trim($part);
            if ($part === '') {
                continue;
            }
            $parts[] = $part;
        }
        return $parts;
    }

    private static function normalizeSchemaPath(string $value): ?string
    {
        $parts = self::splitSchemaPath($value);
        if ($parts === []) {
            return null;
        }
        return implode('.', $parts);
    }

    /**
     * @param array<int, array{name: string, path: string, terminal: bool, children: array}> $children
     * @return array{name: string, path: string, terminal: bool, children: array}
     */
    private static function &upsertSchemaTreeNode(array &$children, string $name, string $path, bool $terminal): array
    {
        foreach ($children as $index => $child) {
            if (($child['path'] ?? '') !== $path) {
                continue;
            }
            if ($terminal) {
                $children[$index]['terminal'] = true;
            }
            return $children[$index];
        }

        $children[] = [
            'name' => $name,
            'path' => $path,
            'terminal' => $terminal,
            'children' => [],
        ];
        $lastIndex = array_key_last($children);
        return $children[$lastIndex];
    }
}
