// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

namespace ScratchBird.Data;

public static class ScratchBirdMetadata
{
    public const string CatalogsQuery = "SELECT schema_id AS catalog_id, schema_name AS catalog_name FROM sys.schemas WHERE is_valid = 1 ORDER BY schema_name";
    public const string SchemasQuery = "SELECT schema_id, schema_name, owner_id, default_tablespace_id FROM sys.schemas WHERE is_valid = 1 ORDER BY schema_name";
    public const string TablesQuery = "SELECT table_schema, table_name, table_type FROM information_schema.tables ORDER BY table_schema, table_name";
    public const string ColumnsQuery = "SELECT table_schema, table_name, column_name, data_type, ordinal_position, is_nullable FROM information_schema.columns ORDER BY table_schema, table_name, ordinal_position";
    public const string IndexesQuery = "SELECT index_id, table_id, index_name, index_type, is_unique FROM sys.indexes WHERE is_valid = 1 ORDER BY table_id, index_name";
    public const string IndexColumnsQuery = "SELECT index_id, column_id, column_name, ordinal_position, is_included FROM sys.index_columns ORDER BY index_id, ordinal_position";
    public const string ConstraintsQuery = "SELECT constraint_id, table_id, constraint_name, constraint_type FROM sys.constraints WHERE is_valid = 1 ORDER BY table_id, constraint_name";
    public const string PrimaryKeysQuery = "SELECT constraint_id, table_id, constraint_name, constraint_type FROM sys.constraints WHERE is_valid = 1 AND lower(constraint_type) IN ('primary key', 'primary') ORDER BY table_id, constraint_name";
    public const string ForeignKeysQuery = "SELECT constraint_id, table_id, constraint_name, constraint_type FROM sys.constraints WHERE is_valid = 1 AND lower(constraint_type) IN ('foreign key', 'foreign') ORDER BY table_id, constraint_name";
    public const string TablePrivilegesQuery = "SELECT table_id, table_name, owner_id AS grantor_id, owner_id AS grantee_id, 'ALL' AS privilege_type FROM sys.tables WHERE is_valid = 1 ORDER BY table_id, table_name";
    public const string ColumnPrivilegesQuery = "SELECT table_id, column_id, column_name, 'ALL' AS privilege_type FROM sys.columns WHERE is_valid = 1 ORDER BY table_id, ordinal_position";
    public const string ProceduresQuery = "SELECT procedure_id, schema_id, procedure_name, routine_type FROM sys.procedures WHERE is_valid = 1 ORDER BY schema_id, procedure_name";
    public const string FunctionsQuery = "SELECT function_id, schema_id, function_name FROM sys.functions WHERE is_valid = 1 ORDER BY schema_id, function_name";
    public const string RoutinesQuery = "SELECT procedure_id AS routine_id, schema_id, procedure_name AS routine_name, routine_type FROM sys.procedures WHERE is_valid = 1 UNION ALL SELECT function_id AS routine_id, schema_id, function_name AS routine_name, 'FUNCTION' AS routine_type FROM sys.functions WHERE is_valid = 1 ORDER BY schema_id, routine_name";
    public const string TypeInfoQuery = "SELECT DISTINCT data_type_id, data_type_name FROM sys.columns WHERE is_valid = 1 ORDER BY data_type_name";
}
