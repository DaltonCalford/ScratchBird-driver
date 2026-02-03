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
	"database/sql"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
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
	db.SetMaxOpenConns(1)
	db.SetMaxIdleConns(1)
	return db
}

func TestIntegrationSelect(t *testing.T) {
	db := openTestDB(t)
	defer db.Close()
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	table := createTempTable(t, db, ctx)
	defer db.Exec("DROP TABLE " + table)
	rows, err := db.QueryContext(ctx, "SELECT value FROM "+table)
	if err != nil {
		t.Fatalf("query error: %v", err)
	}
	rows.Close()
}

func TestIntegrationPrepareBind(t *testing.T) {
	db := openTestDB(t)
	defer db.Close()
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	table := createTempTable(t, db, ctx)
	defer db.Exec("DROP TABLE " + table)
	rows, err := db.QueryContext(ctx, "SELECT value FROM "+table+" WHERE value = ?::INTEGER", 42)
	if err != nil {
		t.Fatalf("query error: %v", err)
	}
	rows.Close()
}

func TestIntegrationTypesFixture(t *testing.T) {
	db := openTestDB(t)
	defer db.Close()
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	applyFixtures(t, db, ctx)
	rows, err := db.QueryContext(ctx, "SELECT * FROM type_coverage")
	if err != nil {
		t.Fatalf("query error: %v", err)
	}
	rows.Close()
}

func TestIntegrationCancel(t *testing.T) {
	db := openTestDB(t)
	defer db.Close()
	cancelSQL := os.Getenv("SCRATCHBIRD_GO_CANCEL_SQL")
	if cancelSQL == "" {
		t.Skip("SCRATCHBIRD_GO_CANCEL_SQL not set")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 200*time.Millisecond)
	defer cancel()
	_, err := db.ExecContext(ctx, cancelSQL)
	if err == nil {
		t.Fatalf("expected cancel error")
	}
	if !errors.Is(err, context.DeadlineExceeded) {
		t.Logf("cancel error: %v", err)
	}
}

func createTempTable(t *testing.T, db *sql.DB, ctx context.Context) string {
	t.Helper()
	table := fmt.Sprintf("scratchbird_go_tmp_%d", time.Now().UnixNano())
	createSQL := "CREATE TABLE " + table + " (value INTEGER)"
	if _, err := db.ExecContext(ctx, createSQL); err != nil {
		t.Fatalf("create table error: %v", err)
	}
	if _, err := db.ExecContext(ctx, "INSERT INTO "+table+" (value) VALUES (42)"); err != nil {
		t.Fatalf("insert error: %v", err)
	}
	return table
}

func applyFixtures(t *testing.T, db *sql.DB, ctx context.Context) {
	t.Helper()
	fixtureDir := os.Getenv("SCRATCHBIRD_FIXTURES_DIR")
	if fixtureDir == "" {
		t.Skip("SCRATCHBIRD_FIXTURES_DIR not set")
	}
	if rows, err := db.QueryContext(ctx, "SELECT 1 FROM type_coverage"); err == nil {
		rows.Close()
		return
	}
	fixtures := []string{"core_fixture.sql", "types_fixture.sql"}
	for _, fixture := range fixtures {
		path := filepath.Join(fixtureDir, fixture)
		data, err := os.ReadFile(path)
		if err != nil {
			t.Fatalf("read fixture error: %v", err)
		}
		statements := splitSQLStatements(string(data))
		for _, statement := range statements {
			if _, err := db.ExecContext(ctx, statement); err != nil {
				if strings.Contains(strings.ToLower(err.Error()), "already exists") {
					continue
				}
				t.Fatalf("fixture error: %v", err)
			}
		}
	}
}

func splitSQLStatements(input string) []string {
	lines := strings.Split(input, "\n")
	filtered := make([]string, 0, len(lines))
	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		if strings.HasPrefix(trimmed, "--") || trimmed == "" {
			continue
		}
		filtered = append(filtered, line)
	}
	joined := strings.Join(filtered, "\n")
	parts := strings.Split(joined, ";")
	statements := make([]string, 0, len(parts))
	for _, part := range parts {
		trimmed := strings.TrimSpace(part)
		if trimmed == "" {
			continue
		}
		statements = append(statements, trimmed)
	}
	return statements
}
