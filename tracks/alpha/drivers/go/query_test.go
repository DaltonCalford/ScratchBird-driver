// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
package scratchbird

import (
	"database/sql/driver"
	"testing"
)

func TestRewritePositional(t *testing.T) {
	query := "SELECT * FROM t WHERE id = ? AND name = ?"
	args := []driver.NamedValue{
		{Ordinal: 1, Value: 42},
		{Ordinal: 2, Value: "Ada"},
	}
	out, err := normalizeQuery(query, args)
	if err != nil {
		t.Fatalf("rewrite error: %v", err)
	}
	expected := "SELECT * FROM t WHERE id = $1 AND name = $2"
	if out.sql != expected {
		t.Fatalf("unexpected query: %s", out.sql)
	}
	if len(out.args) != 2 {
		t.Fatalf("unexpected args: %d", len(out.args))
	}
}

func TestRewriteNamed(t *testing.T) {
	query := "SELECT * FROM users WHERE name = @name AND active = :active"
	args := []driver.NamedValue{
		{Name: "name", Value: "Ada"},
		{Name: "active", Value: true},
	}
	out, err := normalizeQuery(query, args)
	if err != nil {
		t.Fatalf("rewrite error: %v", err)
	}
	expected := "SELECT * FROM users WHERE name = $1 AND active = $2"
	if out.sql != expected {
		t.Fatalf("unexpected query: %s", out.sql)
	}
	if len(out.args) != 2 {
		t.Fatalf("unexpected args: %d", len(out.args))
	}
}
