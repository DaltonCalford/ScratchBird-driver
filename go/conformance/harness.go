package conformance

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"strings"

	_ "github.com/scratchbird/scratchbird-go"
)

type Manifest struct {
	SchemaVersion   string     `json:"schema_version"`
	ProtocolVersion string     `json:"protocol_version"`
	Suite           string     `json:"suite"`
	Fixtures        []string   `json:"fixtures"`
	Requires        []string   `json:"requires"`
	Tests           []TestSpec `json:"tests"`
}

type TestSpec struct {
	ID         string        `json:"id"`
	Kind       string        `json:"kind"`
	SQL        string        `json:"sql,omitempty"`
	Params     []interface{} `json:"params,omitempty"`
	ExpectRows *int          `json:"expect_rows,omitempty"`
}

type TestResult struct {
	TestID  string        `json:"test_id"`
	Status  string        `json:"status"`
	Rows    [][]any       `json:"rows,omitempty"`
	Columns []string      `json:"columns,omitempty"`
	Errors  []string      `json:"errors,omitempty"`
}

type Summary struct {
	SchemaVersion   string       `json:"schema_version"`
	ProtocolVersion string       `json:"protocol_version"`
	Suite           string       `json:"suite"`
	Results         []TestResult `json:"results"`
}

func LoadManifest(path string) (*Manifest, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	var manifest Manifest
	if err := json.Unmarshal(data, &manifest); err != nil {
		return nil, err
	}
	return &manifest, nil
}

func RunManifest(ctx context.Context, dsn, manifestPath string) (*Summary, error) {
	manifest, err := LoadManifest(manifestPath)
	if err != nil {
		return nil, err
	}
	fixtureDir := filepath.Dir(manifestPath)
	return Run(ctx, dsn, fixtureDir, manifest)
}

func Run(ctx context.Context, dsn, fixtureDir string, manifest *Manifest) (*Summary, error) {
	if manifest == nil {
		return nil, errors.New("manifest is required")
	}
	if dsn == "" {
		return nil, errors.New("dsn is required")
	}
	if err := applyFixtures(ctx, dsn, fixtureDir, manifest.Fixtures); err != nil {
		return nil, err
	}
	results, err := runTests(ctx, dsn, manifest.Tests)
	if err != nil {
		return nil, err
	}
	return &Summary{
		SchemaVersion:   manifest.SchemaVersion,
		ProtocolVersion: manifest.ProtocolVersion,
		Suite:           manifest.Suite,
		Results:         results,
	}, nil
}

func applyFixtures(ctx context.Context, dsn, fixtureDir string, fixtures []string) error {
	if len(fixtures) == 0 {
		return nil
	}
	db, err := sql.Open("scratchbird", dsn)
	if err != nil {
		return err
	}
	defer db.Close()
	for _, fixture := range fixtures {
		path := filepath.Join(fixtureDir, fixture)
		data, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		statements := splitSQLStatements(string(data))
		for _, statement := range statements {
			if _, err := db.ExecContext(ctx, statement); err != nil {
				return err
			}
		}
	}
	return nil
}

func runTests(ctx context.Context, dsn string, tests []TestSpec) ([]TestResult, error) {
	db, err := sql.Open("scratchbird", dsn)
	if err != nil {
		return nil, err
	}
	defer db.Close()
	results := make([]TestResult, 0, len(tests))
	for _, test := range tests {
		result := TestResult{TestID: test.ID}
		switch test.Kind {
		case "auth":
			err = db.PingContext(ctx)
		case "prepare_bind":
			result, err = runPrepareBind(ctx, db, test)
		case "query":
			result, err = runQuery(ctx, db, test)
		default:
			err = errors.New("unknown test kind: " + test.Kind)
		}
		if err != nil {
			result.Status = "error"
			result.Errors = append(result.Errors, err.Error())
		} else if result.Status == "" {
			result.Status = "ok"
		}
		results = append(results, result)
		err = nil
	}
	return results, nil
}

func runQuery(ctx context.Context, db *sql.DB, test TestSpec) (TestResult, error) {
	sqlText := strings.TrimSpace(test.SQL)
	if sqlText == "" {
		sqlText = "SELECT 1"
	}
	rows, err := db.QueryContext(ctx, sqlText)
	if err != nil {
		return TestResult{TestID: test.ID}, err
	}
	defer rows.Close()
	return readRows(test.ID, rows)
}

func runPrepareBind(ctx context.Context, db *sql.DB, test TestSpec) (TestResult, error) {
	if strings.TrimSpace(test.SQL) == "" {
		return TestResult{TestID: test.ID}, errors.New("prepare_bind requires sql")
	}
	stmt, err := db.PrepareContext(ctx, test.SQL)
	if err != nil {
		return TestResult{TestID: test.ID}, err
	}
	defer stmt.Close()
	params := normalizeParams(test.Params)
	rows, err := stmt.QueryContext(ctx, params...)
	if err != nil {
		return TestResult{TestID: test.ID}, err
	}
	defer rows.Close()
	return readRows(test.ID, rows)
}

func readRows(testID string, rows *sql.Rows) (TestResult, error) {
	cols, err := rows.Columns()
	if err != nil {
		return TestResult{TestID: testID}, err
	}
	result := TestResult{TestID: testID, Columns: cols, Status: "ok"}
	for rows.Next() {
		dest := make([]any, len(cols))
		for i := range dest {
			var holder any
			dest[i] = &holder
		}
		if err := rows.Scan(dest...); err != nil {
			return TestResult{TestID: testID}, err
		}
		row := make([]any, len(cols))
		for i, item := range dest {
			row[i] = *(item.(*any))
		}
		result.Rows = append(result.Rows, row)
	}
	if err := rows.Err(); err != nil {
		return TestResult{TestID: testID}, err
	}
	return result, nil
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

func normalizeParams(params []any) []any {
	if len(params) == 0 {
		return params
	}
	out := make([]any, 0, len(params))
	for _, param := range params {
		switch v := param.(type) {
		case float64:
			if v == float64(int64(v)) {
				out = append(out, int64(v))
			} else {
				out = append(out, v)
			}
		default:
			out = append(out, param)
		}
	}
	return out
}
