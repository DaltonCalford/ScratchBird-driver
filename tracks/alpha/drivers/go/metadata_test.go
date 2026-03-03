// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
package scratchbird

import (
	"context"
	"fmt"
	"net"
	"reflect"
	"testing"
)

func TestMetadataExpandSchemaNamesDefaultKeepsPhysicalRows(t *testing.T) {
	schemas := MetadataExpandSchemaNames([]string{
		"sys",
		"users.alice.dev",
		"users.bob.dev",
		"analytics.prod",
	}, "", false)

	expected := []string{"sys", "users.alice.dev", "users.bob.dev", "analytics.prod"}
	if !reflect.DeepEqual(schemas, expected) {
		t.Fatalf("unexpected schemas: got %v want %v", schemas, expected)
	}
}

func TestMetadataExpandSchemaNamesCanExpandParentsForRecursiveNavigation(t *testing.T) {
	schemas := MetadataExpandSchemaNames([]string{
		"analytics.prod",
		"sys",
		"users.alice.dev",
		"users.bob.dev",
		"users..bob.dev",
		"",
	}, "", true)

	expected := []string{
		"analytics",
		"analytics.prod",
		"sys",
		"users",
		"users.alice",
		"users.alice.dev",
		"users.bob",
		"users.bob.dev",
	}
	if !reflect.DeepEqual(schemas, expected) {
		t.Fatalf("unexpected expanded schemas: got %v want %v", schemas, expected)
	}
}

func TestMetadataExpandSchemaNamesExpansionRespectsPattern(t *testing.T) {
	schemas := MetadataExpandSchemaNames([]string{
		"users.alice.dev",
		"users.bob.dev",
		"analytics.prod",
	}, "users.%", true)

	expected := []string{"users.alice", "users.alice.dev", "users.bob", "users.bob.dev"}
	if !reflect.DeepEqual(schemas, expected) {
		t.Fatalf("unexpected filtered schemas: got %v want %v", schemas, expected)
	}
}

func TestMetadataBuildSchemaTreeSmoke(t *testing.T) {
	roots := MetadataBuildSchemaTree([]string{
		"sys",
		"users",
		"users.alice.dev",
		"users.alice.prod",
		"users.bob.dev",
		"users.bob.dev", // duplicate input path
		"analytics.dev",
		"analytics.prod",
	})

	if len(roots) != 3 {
		t.Fatalf("expected 3 roots, got %d", len(roots))
	}

	users := findMetadataNodeByName(roots, "users")
	if users == nil {
		t.Fatalf("expected users root")
	}

	alice := findMetadataNodeByName(users.Children, "alice")
	bob := findMetadataNodeByName(users.Children, "bob")
	if alice == nil {
		t.Fatalf("expected users.alice node")
	}
	if bob == nil {
		t.Fatalf("expected users.bob node")
	}

	if findMetadataNodeByName(alice.Children, "dev") == nil {
		t.Fatalf("expected users.alice.dev node")
	}
	if findMetadataNodeByName(alice.Children, "prod") == nil {
		t.Fatalf("expected users.alice.prod node")
	}
	if findMetadataNodeByName(bob.Children, "dev") == nil {
		t.Fatalf("expected users.bob.dev node")
	}
	if len(bob.Children) != 1 {
		t.Fatalf("expected one unique users.bob child, got %d", len(bob.Children))
	}

	sys := findMetadataNodeByName(roots, "sys")
	if sys == nil || !sys.Terminal {
		t.Fatalf("expected terminal sys node")
	}
}

func TestResolveMetadataCollectionQueryAliases(t *testing.T) {
	query, err := ResolveMetadataCollectionQuery("")
	if err != nil {
		t.Fatalf("resolve default metadata query failed: %v", err)
	}
	if query != MetadataTablesQuery() {
		t.Fatalf("default metadata query mismatch: got %q want %q", query, MetadataTablesQuery())
	}

	cases := map[string]string{
		"schemas":          MetadataSchemasQuery(),
		"indexcolumns":     MetadataIndexColumnsQuery(),
		"pk":               MetadataPrimaryKeysQuery(),
		"foreign_keys":     MetadataForeignKeysQuery(),
		"table_privileges": MetadataTablePrivilegesQuery(),
		"types":            MetadataTypeInfoQuery(),
	}
	for input, expected := range cases {
		got, err := ResolveMetadataCollectionQuery(input)
		if err != nil {
			t.Fatalf("resolve metadata query for %q failed: %v", input, err)
		}
		if got != expected {
			t.Fatalf("metadata query mismatch for %q: got %q want %q", input, got, expected)
		}
	}

	if _, err := ResolveMetadataCollectionQuery("unsupported_metadata_family"); err == nil {
		t.Fatalf("expected unsupported metadata collection error")
	}
}

func TestQueryMetadataRoutesCollectionQuery(t *testing.T) {
	client, server := net.Pipe()
	defer client.Close()

	errCh := make(chan error, 1)
	go func() {
		defer close(errCh)
		defer server.Close()

		msg, err := readMessage(server)
		if err != nil {
			errCh <- fmt.Errorf("read metadata query message: %w", err)
			return
		}
		if msg.header.typ != msgQuery {
			errCh <- fmt.Errorf("expected %v, got %v", msgQuery, msg.header.typ)
			return
		}
		sqlText, err := queryPayloadSQL(msg.body)
		if err != nil {
			errCh <- err
			return
		}
		if sqlText != MetadataTablesQuery() {
			errCh <- fmt.Errorf("metadata query mismatch: got %q want %q", sqlText, MetadataTablesQuery())
			return
		}

		if _, err := server.Write(encodeMessage(messageHeader{typ: msgCommandComplete}, testCommandCompletePayload(0, 0, "SELECT"))); err != nil {
			errCh <- fmt.Errorf("write metadata command complete: %w", err)
			return
		}
		if _, err := server.Write(encodeMessage(messageHeader{typ: msgReady}, testReadyPayload(0, 0, 0))); err != nil {
			errCh <- fmt.Errorf("write metadata ready: %w", err)
			return
		}
		errCh <- nil
	}()

	conn := &Conn{
		config: defaultConfig(),
		raw:    client,
	}
	rows, err := conn.QueryMetadata(context.Background(), "tables")
	if err != nil {
		t.Fatalf("query metadata failed: %v", err)
	}
	if rows == nil {
		t.Fatalf("expected rows, got nil")
	}
	if err := rows.Close(); err != nil {
		t.Fatalf("close metadata rows failed: %v", err)
	}
	if err := <-errCh; err != nil {
		t.Fatal(err)
	}
}

func TestQueryMetadataRejectsUnsupportedCollection(t *testing.T) {
	client, server := net.Pipe()
	defer client.Close()
	defer server.Close()

	conn := &Conn{
		config: defaultConfig(),
		raw:    client,
	}
	_, err := conn.QueryMetadata(context.Background(), "no_such_metadata")
	requireDriverError(t, err, ErrNotSupported, "0A000")
}

func findMetadataNodeByName(nodes []*MetadataSchemaTreeNode, name string) *MetadataSchemaTreeNode {
	for _, node := range nodes {
		if node != nil && node.Name == name {
			return node
		}
	}
	return nil
}

func queryPayloadSQL(payload []byte) (string, error) {
	if len(payload) < 13 {
		return "", fmt.Errorf("query payload too short: %d", len(payload))
	}
	sqlWithTerminator := payload[12:]
	if sqlWithTerminator[len(sqlWithTerminator)-1] == 0 {
		sqlWithTerminator = sqlWithTerminator[:len(sqlWithTerminator)-1]
	}
	return string(sqlWithTerminator), nil
}
