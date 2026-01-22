package scratchbird

import (
	"context"
	"database/sql"
	"os"
	"testing"
	"time"
)

func TestIntegrationSelect(t *testing.T) {
	dsn := os.Getenv("SCRATCHBIRD_GO_URL")
	if dsn == "" {
		t.Skip("SCRATCHBIRD_GO_URL not set")
	}
	db, err := sql.Open("scratchbird", dsn)
	if err != nil {
		t.Fatalf("open error: %v", err)
	}
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
