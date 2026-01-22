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
	out, err := rewriteQuery(query, args)
	if err != nil {
		t.Fatalf("rewrite error: %v", err)
	}
	expected := "SELECT * FROM t WHERE id = 42 AND name = 'Ada'"
	if out != expected {
		t.Fatalf("unexpected query: %s", out)
	}
}

func TestRewriteNamed(t *testing.T) {
	query := "SELECT * FROM users WHERE name = @name AND active = :active"
	args := []driver.NamedValue{
		{Name: "name", Value: "Ada"},
		{Name: "active", Value: true},
	}
	out, err := rewriteQuery(query, args)
	if err != nil {
		t.Fatalf("rewrite error: %v", err)
	}
	expected := "SELECT * FROM users WHERE name = 'Ada' AND active = TRUE"
	if out != expected {
		t.Fatalf("unexpected query: %s", out)
	}
}
