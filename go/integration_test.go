package scratchbird

import (
	"context"
	"database/sql"
	"os"
	"testing"
	"time"
)

func openTestDB(t *testing.T) *sql.DB {
	dsn := os.Getenv("SCRATCHBIRD_GO_URL")
	if dsn == "" {
		t.Skip("SCRATCHBIRD_GO_URL not set")
	}
	db, err := sql.Open("scratchbird", dsn)
	if err != nil {
		t.Fatalf("open error: %v", err)
	}
	return db
}

func TestIntegrationSelect(t *testing.T) {
	db := openTestDB(t)
	defer db.Close()
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	var value int
	if err := db.QueryRowContext(ctx, "SELECT 1").Scan(&value); err != nil {
		t.Fatalf("query error: %v", err)
	}
	if value != 1 {
		t.Fatalf("unexpected value: %d", value)
	}
}

func TestIntegrationPrepareBind(t *testing.T) {
	db := openTestDB(t)
	defer db.Close()
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	var value int
	if err := db.QueryRowContext(ctx, "SELECT ?::INTEGER", 42).Scan(&value); err != nil {
		t.Fatalf("query error: %v", err)
	}
	if value != 42 {
		t.Fatalf("unexpected value: %d", value)
	}
}

func TestIntegrationTypesFixture(t *testing.T) {
	db := openTestDB(t)
	defer db.Close()
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	rows, err := db.QueryContext(ctx, "SELECT * FROM sb_conformance.type_coverage")
	if err != nil {
		t.Fatalf("query error: %v", err)
	}
	defer rows.Close()
	cols, err := rows.Columns()
	if err != nil {
		t.Fatalf("columns error: %v", err)
	}
	if !rows.Next() {
		t.Fatalf("no rows returned")
	}
	dest := make([]any, len(cols))
	ptrs := make([]any, len(cols))
	for i := range dest {
		ptrs[i] = &dest[i]
	}
	if err := rows.Scan(ptrs...); err != nil {
		t.Fatalf("scan error: %v", err)
	}
}
