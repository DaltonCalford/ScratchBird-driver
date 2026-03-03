// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
package scratchbird

import (
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

func findMetadataNodeByName(nodes []*MetadataSchemaTreeNode, name string) *MetadataSchemaTreeNode {
	for _, node := range nodes {
		if node != nil && node.Name == name {
			return node
		}
	}
	return nil
}
