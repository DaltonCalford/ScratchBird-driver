{ ScratchBird-driver
  Copyright (c) 2025-2026 Dalton Calford

  Licensed under the Initial Developer's Public License Version 1.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at:
  https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/ }

unit ScratchBird.Metadata;

interface

function MetadataSchemasQuery: string;
function MetadataTablesQuery: string;
function MetadataColumnsQuery: string;
function MetadataIndexesQuery: string;
function MetadataIndexColumnsQuery: string;
function MetadataConstraintsQuery: string;
function MetadataProceduresQuery: string;
function MetadataFunctionsQuery: string;

implementation

function MetadataSchemasQuery: string;
begin
  Result := 'SELECT schema_id, schema_name, owner_id, default_tablespace_id FROM sys.schemas WHERE is_valid = 1 ORDER BY schema_name';
end;

function MetadataTablesQuery: string;
begin
  Result := 'SELECT table_id, schema_id, table_name, table_type, owner_id FROM sys.tables WHERE is_valid = 1 ORDER BY table_name';
end;

function MetadataColumnsQuery: string;
begin
  Result := 'SELECT column_id, table_id, column_name, data_type_id, data_type_name, ordinal_position, is_nullable, default_value, domain_id, collation_id, charset_id, is_identity, is_generated, generation_expression FROM sys.columns WHERE is_valid = 1 ORDER BY table_id, ordinal_position';
end;

function MetadataIndexesQuery: string;
begin
  Result := 'SELECT index_id, table_id, index_name, index_type, is_unique FROM sys.indexes WHERE is_valid = 1 ORDER BY table_id, index_name';
end;

function MetadataIndexColumnsQuery: string;
begin
  Result := 'SELECT index_id, column_id, column_name, ordinal_position, is_included FROM sys.index_columns ORDER BY index_id, ordinal_position';
end;

function MetadataConstraintsQuery: string;
begin
  Result := 'SELECT constraint_id, table_id, constraint_name, constraint_type FROM sys.constraints WHERE is_valid = 1 ORDER BY table_id, constraint_name';
end;

function MetadataProceduresQuery: string;
begin
  Result := 'SELECT procedure_id, schema_id, procedure_name, routine_type FROM sys.procedures WHERE is_valid = 1 ORDER BY schema_id, procedure_name';
end;

function MetadataFunctionsQuery: string;
begin
  Result := 'SELECT function_id, schema_id, function_name FROM sys.functions WHERE is_valid = 1 ORDER BY schema_id, function_name';
end;

end.
