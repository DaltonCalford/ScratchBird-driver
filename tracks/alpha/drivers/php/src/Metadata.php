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
    public const SCHEMAS_QUERY = "SELECT schema_id, schema_name, owner_id, default_tablespace_id FROM sys.schemas WHERE is_valid = 1 ORDER BY schema_name";
    public const TABLES_QUERY = "SELECT table_id, schema_id, table_name, table_type, owner_id FROM sys.tables WHERE is_valid = 1 ORDER BY table_name";
    public const COLUMNS_QUERY = "SELECT column_id, table_id, column_name, data_type_id, data_type_name, ordinal_position, is_nullable, default_value, domain_id, collation_id, charset_id, is_identity, is_generated, generation_expression FROM sys.columns WHERE is_valid = 1 ORDER BY table_id, ordinal_position";
    public const INDEXES_QUERY = "SELECT index_id, table_id, index_name, index_type, is_unique FROM sys.indexes WHERE is_valid = 1 ORDER BY table_id, index_name";
    public const INDEX_COLUMNS_QUERY = "SELECT index_id, column_id, column_name, ordinal_position, is_included FROM sys.index_columns ORDER BY index_id, ordinal_position";
    public const CONSTRAINTS_QUERY = "SELECT constraint_id, table_id, constraint_name, constraint_type FROM sys.constraints WHERE is_valid = 1 ORDER BY table_id, constraint_name";
    public const PROCEDURES_QUERY = "SELECT procedure_id, schema_id, procedure_name, routine_type FROM sys.procedures WHERE is_valid = 1 ORDER BY schema_id, procedure_name";
    public const FUNCTIONS_QUERY = "SELECT function_id, schema_id, function_name FROM sys.functions WHERE is_valid = 1 ORDER BY schema_id, function_name";

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
}
