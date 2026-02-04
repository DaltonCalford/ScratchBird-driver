// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
package scratchbird

// Metadata helper queries (sys.*) per METADATA_SCHEMA_CONTRACT.md.
const (
	metadataSchemasQuery     = "SELECT schema_id, schema_name, owner_id, default_tablespace_id FROM sys.schemas WHERE is_valid = 1 ORDER BY schema_name"
	metadataTablesQuery      = "SELECT table_id, schema_id, table_name, table_type, owner_id FROM sys.tables WHERE is_valid = 1 ORDER BY table_name"
	metadataColumnsQuery     = "SELECT column_id, table_id, column_name, data_type_id, data_type_name, ordinal_position, is_nullable, default_value, domain_id, collation_id, charset_id, is_identity, is_generated, generation_expression FROM sys.columns WHERE is_valid = 1 ORDER BY table_id, ordinal_position"
	metadataIndexesQuery     = "SELECT index_id, table_id, index_name, index_type, is_unique FROM sys.indexes WHERE is_valid = 1 ORDER BY table_id, index_name"
	metadataIndexColumnsQuery = "SELECT index_id, column_id, column_name, ordinal_position, is_included FROM sys.index_columns ORDER BY index_id, ordinal_position"
	metadataConstraintsQuery = "SELECT constraint_id, table_id, constraint_name, constraint_type FROM sys.constraints WHERE is_valid = 1 ORDER BY table_id, constraint_name"
	metadataProceduresQuery  = "SELECT procedure_id, schema_id, procedure_name, routine_type FROM sys.procedures WHERE is_valid = 1 ORDER BY schema_id, procedure_name"
	metadataFunctionsQuery   = "SELECT function_id, schema_id, function_name FROM sys.functions WHERE is_valid = 1 ORDER BY schema_id, function_name"
)

func MetadataSchemasQuery() string     { return metadataSchemasQuery }
func MetadataTablesQuery() string      { return metadataTablesQuery }
func MetadataColumnsQuery() string     { return metadataColumnsQuery }
func MetadataIndexesQuery() string     { return metadataIndexesQuery }
func MetadataIndexColumnsQuery() string { return metadataIndexColumnsQuery }
func MetadataConstraintsQuery() string { return metadataConstraintsQuery }
func MetadataProceduresQuery() string  { return metadataProceduresQuery }
func MetadataFunctionsQuery() string   { return metadataFunctionsQuery }
