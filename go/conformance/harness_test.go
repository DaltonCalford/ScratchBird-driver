// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
package conformance

import (
	"context"
	"encoding/json"
	"os"
	"testing"
	"time"
)

func TestConformanceManifest(t *testing.T) {
	dsn := os.Getenv("SCRATCHBIRD_GO_URL")
	if dsn == "" {
		t.Skip("SCRATCHBIRD_GO_URL not set")
	}
	manifestPath := os.Getenv("SCRATCHBIRD_CONFORMANCE_MANIFEST")
	if manifestPath == "" {
		t.Skip("SCRATCHBIRD_CONFORMANCE_MANIFEST not set")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()

	summary, err := RunManifest(ctx, dsn, manifestPath)
	if err != nil {
		t.Fatalf("conformance run failed: %v", err)
	}
	if len(summary.Results) == 0 {
		t.Fatalf("conformance run returned no results")
	}
	for _, result := range summary.Results {
		if result.Status != "ok" && result.Status != "skipped" {
			payload, _ := json.Marshal(summary)
			t.Fatalf("conformance test %q failed: %s", result.TestID, string(payload))
		}
	}
}
