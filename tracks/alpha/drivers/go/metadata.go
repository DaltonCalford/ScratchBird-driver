// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
package scratchbird

import (
	"fmt"
	"regexp"
	"strings"
)

// Metadata helper queries (sys.*) per METADATA_SCHEMA_CONTRACT.md.
const (
	metadataCatalogsQuery     = "SELECT schema_id AS catalog_id, schema_name AS catalog_name FROM sys.schemas WHERE is_valid = 1 ORDER BY schema_name"
	metadataSchemasQuery      = "SELECT schema_id, schema_name, owner_id, default_tablespace_id FROM sys.schemas WHERE is_valid = 1 ORDER BY schema_name"
	metadataTablesQuery       = "SELECT table_id, schema_id, table_name, table_type, owner_id FROM sys.tables WHERE is_valid = 1 ORDER BY table_name"
	metadataColumnsQuery      = "SELECT column_id, table_id, column_name, data_type_id, data_type_name, ordinal_position, is_nullable, default_value, domain_id, collation_id, charset_id, is_identity, is_generated, generation_expression FROM sys.columns WHERE is_valid = 1 ORDER BY table_id, ordinal_position"
	metadataIndexesQuery      = "SELECT index_id, table_id, index_name, index_type, is_unique FROM sys.indexes WHERE is_valid = 1 ORDER BY table_id, index_name"
	metadataIndexColumnsQuery = "SELECT index_id, column_id, column_name, ordinal_position, is_included FROM sys.index_columns ORDER BY index_id, ordinal_position"
	metadataConstraintsQuery  = "SELECT constraint_id, table_id, constraint_name, constraint_type FROM sys.constraints WHERE is_valid = 1 ORDER BY table_id, constraint_name"
	metadataPrimaryKeysQuery  = "SELECT constraint_id, table_id, constraint_name, constraint_type FROM sys.constraints WHERE is_valid = 1 AND lower(constraint_type) IN ('primary key', 'primary') ORDER BY table_id, constraint_name"
	metadataForeignKeysQuery  = "SELECT constraint_id, table_id, constraint_name, constraint_type FROM sys.constraints WHERE is_valid = 1 AND lower(constraint_type) IN ('foreign key', 'foreign') ORDER BY table_id, constraint_name"
	metadataTablePrivsQuery   = "SELECT table_id, table_name, owner_id AS grantor_id, owner_id AS grantee_id, 'ALL' AS privilege_type FROM sys.tables WHERE is_valid = 1 ORDER BY table_id, table_name"
	metadataColumnPrivsQuery  = "SELECT table_id, column_id, column_name, 'ALL' AS privilege_type FROM sys.columns WHERE is_valid = 1 ORDER BY table_id, ordinal_position"
	metadataProceduresQuery   = "SELECT procedure_id, schema_id, procedure_name, routine_type FROM sys.procedures WHERE is_valid = 1 ORDER BY schema_id, procedure_name"
	metadataFunctionsQuery    = "SELECT function_id, schema_id, function_name FROM sys.functions WHERE is_valid = 1 ORDER BY schema_id, function_name"
	metadataTypeInfoQuery     = "SELECT DISTINCT data_type_id, data_type_name FROM sys.columns WHERE is_valid = 1 ORDER BY data_type_name"
)

func MetadataCatalogsQuery() string     { return metadataCatalogsQuery }
func MetadataSchemasQuery() string      { return metadataSchemasQuery }
func MetadataTablesQuery() string       { return metadataTablesQuery }
func MetadataColumnsQuery() string      { return metadataColumnsQuery }
func MetadataIndexesQuery() string      { return metadataIndexesQuery }
func MetadataIndexColumnsQuery() string { return metadataIndexColumnsQuery }
func MetadataConstraintsQuery() string  { return metadataConstraintsQuery }
func MetadataPrimaryKeysQuery() string  { return metadataPrimaryKeysQuery }
func MetadataForeignKeysQuery() string  { return metadataForeignKeysQuery }
func MetadataTablePrivilegesQuery() string {
	return metadataTablePrivsQuery
}
func MetadataColumnPrivilegesQuery() string {
	return metadataColumnPrivsQuery
}
func MetadataProceduresQuery() string { return metadataProceduresQuery }
func MetadataFunctionsQuery() string  { return metadataFunctionsQuery }
func MetadataTypeInfoQuery() string   { return metadataTypeInfoQuery }

var metadataCollectionQueries = map[string]string{
	"catalogs":          metadataCatalogsQuery,
	"schemas":           metadataSchemasQuery,
	"tables":            metadataTablesQuery,
	"columns":           metadataColumnsQuery,
	"indexes":           metadataIndexesQuery,
	"index_columns":     metadataIndexColumnsQuery,
	"constraints":       metadataConstraintsQuery,
	"primary_keys":      metadataPrimaryKeysQuery,
	"foreign_keys":      metadataForeignKeysQuery,
	"table_privileges":  metadataTablePrivsQuery,
	"column_privileges": metadataColumnPrivsQuery,
	"procedures":        metadataProceduresQuery,
	"functions":         metadataFunctionsQuery,
	"type_info":         metadataTypeInfoQuery,
}

var metadataCollectionAliases = map[string]string{
	"catalog":           "catalogs",
	"catalogs":          "catalogs",
	"schema":            "schemas",
	"schemas":           "schemas",
	"table":             "tables",
	"tables":            "tables",
	"column":            "columns",
	"columns":           "columns",
	"index":             "indexes",
	"indexes":           "indexes",
	"indexcolumns":      "index_columns",
	"index_columns":     "index_columns",
	"constraint":        "constraints",
	"constraints":       "constraints",
	"primarykey":        "primary_keys",
	"primarykeys":       "primary_keys",
	"primary_keys":      "primary_keys",
	"pk":                "primary_keys",
	"foreignkey":        "foreign_keys",
	"foreignkeys":       "foreign_keys",
	"foreign_keys":      "foreign_keys",
	"fk":                "foreign_keys",
	"tableprivileges":   "table_privileges",
	"table_privileges":  "table_privileges",
	"columnprivileges":  "column_privileges",
	"column_privileges": "column_privileges",
	"procedure":         "procedures",
	"procedures":        "procedures",
	"function":          "functions",
	"functions":         "functions",
	"typeinfo":          "type_info",
	"type_info":         "type_info",
	"types":             "type_info",
}

func NormalizeMetadataCollectionName(collection string) (string, error) {
	normalized := strings.ToLower(strings.TrimSpace(collection))
	if normalized == "" {
		normalized = "tables"
	}
	resolved, ok := metadataCollectionAliases[normalized]
	if !ok {
		return "", fmt.Errorf("metadata collection %q is not supported", collection)
	}
	return resolved, nil
}

func ResolveMetadataCollectionQuery(collection string) (string, error) {
	resolved, err := NormalizeMetadataCollectionName(collection)
	if err != nil {
		return "", err
	}
	query, ok := metadataCollectionQueries[resolved]
	if !ok {
		return "", fmt.Errorf("metadata collection %q is not supported", collection)
	}
	return query, nil
}

// MetadataSchemaTreeNode represents one node in a dotted-schema navigation tree.
type MetadataSchemaTreeNode struct {
	Name     string
	FullPath string
	Terminal bool
	Children []*MetadataSchemaTreeNode
}

// MetadataExpandSchemaNames optionally expands dotted parent schemas while preserving insertion order.
func MetadataExpandSchemaNames(schemaNames []string, schemaPattern string, expandParents bool) []string {
	matches := metadataSchemaPatternMatcher(schemaPattern)
	out := make([]string, 0, len(schemaNames))
	seen := make(map[string]struct{}, len(schemaNames))

	for _, raw := range schemaNames {
		schemaName := normalizeMetadataSchemaPath(raw)
		if schemaName == "" {
			continue
		}
		if expandParents {
			appendSchemaWithParents(&out, seen, matches, schemaName)
			continue
		}
		if matches(schemaName) {
			appendSchemaUnique(&out, seen, schemaName)
		}
	}
	return out
}

// MetadataBuildSchemaTree converts dotted schema paths into a recursive tree shape.
func MetadataBuildSchemaTree(schemaPaths []string) []*MetadataSchemaTreeNode {
	nodesByPath := make(map[string]*MetadataSchemaTreeNode, len(schemaPaths))
	roots := make([]*MetadataSchemaTreeNode, 0)

	for _, raw := range schemaPaths {
		normalized := normalizeMetadataSchemaPath(raw)
		if normalized == "" {
			continue
		}

		var parent *MetadataSchemaTreeNode
		var currentPath strings.Builder
		for _, segment := range strings.Split(normalized, ".") {
			if segment == "" {
				continue
			}
			if currentPath.Len() > 0 {
				currentPath.WriteByte('.')
			}
			currentPath.WriteString(segment)
			fullPath := currentPath.String()

			node, exists := nodesByPath[fullPath]
			if !exists {
				node = &MetadataSchemaTreeNode{Name: segment, FullPath: fullPath}
				nodesByPath[fullPath] = node
				if parent == nil {
					roots = append(roots, node)
				} else {
					parent.Children = append(parent.Children, node)
				}
			}
			parent = node
		}
		if parent != nil {
			parent.Terminal = true
		}
	}

	return roots
}

func appendSchemaWithParents(out *[]string, seen map[string]struct{}, matches func(string) bool, schemaName string) {
	var current strings.Builder
	for _, segment := range strings.Split(schemaName, ".") {
		if segment == "" {
			continue
		}
		if current.Len() > 0 {
			current.WriteByte('.')
		}
		current.WriteString(segment)
		candidate := current.String()
		if matches(candidate) {
			appendSchemaUnique(out, seen, candidate)
		}
	}
}

func appendSchemaUnique(out *[]string, seen map[string]struct{}, schemaName string) {
	if _, exists := seen[schemaName]; exists {
		return
	}
	seen[schemaName] = struct{}{}
	*out = append(*out, schemaName)
}

func normalizeMetadataSchemaPath(schemaPath string) string {
	segments := strings.Split(schemaPath, ".")
	out := make([]string, 0, len(segments))
	for _, segment := range segments {
		segment = strings.TrimSpace(segment)
		if segment == "" {
			continue
		}
		out = append(out, segment)
	}
	return strings.Join(out, ".")
}

func metadataSchemaPatternMatcher(pattern string) func(string) bool {
	pattern = strings.TrimSpace(pattern)
	if pattern == "" {
		return func(string) bool { return true }
	}

	rx, err := regexp.Compile(metadataPatternToRegex(pattern))
	if err != nil {
		return func(string) bool { return false }
	}

	return func(value string) bool {
		if value == "" {
			return false
		}
		return rx.MatchString(value)
	}
}

func metadataPatternToRegex(pattern string) string {
	var out strings.Builder
	out.WriteString("(?i)^")
	escaped := false

	for _, ch := range pattern {
		if escaped {
			out.WriteString(regexp.QuoteMeta(string(ch)))
			escaped = false
			continue
		}
		switch ch {
		case '\\':
			escaped = true
		case '%':
			out.WriteString(".*")
		case '_':
			out.WriteByte('.')
		default:
			out.WriteString(regexp.QuoteMeta(string(ch)))
		}
	}

	out.WriteByte('$')
	return out.String()
}
