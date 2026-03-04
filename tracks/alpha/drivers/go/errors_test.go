// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
package scratchbird

import "testing"

func TestMapSQLStateKnownMappings(t *testing.T) {
	tests := []struct {
		name     string
		sqlState string
		wantKind ErrorKind
	}{
		{name: "warning", sqlState: "01000", wantKind: ErrWarning},
		{name: "no data", sqlState: "02000", wantKind: ErrNoData},
		{name: "connection", sqlState: "08006", wantKind: ErrConnection},
		{name: "not supported", sqlState: "0A000", wantKind: ErrNotSupported},
		{name: "data", sqlState: "22P02", wantKind: ErrData},
		{name: "integrity", sqlState: "23505", wantKind: ErrIntegrity},
		{name: "auth", sqlState: "28P01", wantKind: ErrAuth},
		{name: "transaction", sqlState: "40001", wantKind: ErrTransaction},
		{name: "syntax", sqlState: "42601", wantKind: ErrSyntax},
		{name: "resource", sqlState: "53300", wantKind: ErrResource},
		{name: "limit", sqlState: "54000", wantKind: ErrLimit},
		{name: "operator", sqlState: "57014", wantKind: ErrOperator},
		{name: "system", sqlState: "58000", wantKind: ErrSystem},
		{name: "internal", sqlState: "XX000", wantKind: ErrInternal},
	}

	for _, tc := range tests {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			if got := mapSQLState(tc.sqlState); got != tc.wantKind {
				t.Fatalf("mapSQLState(%q) mismatch: got %q want %q", tc.sqlState, got, tc.wantKind)
			}
		})
	}
}

func TestMapSQLStateUnknownAndInvalidLength(t *testing.T) {
	if got := mapSQLState("ZZZZZ"); got != ErrUnknown {
		t.Fatalf("expected unknown kind for unmapped SQLSTATE, got %q", got)
	}
	if got := mapSQLState("123"); got != ErrUnknown {
		t.Fatalf("expected unknown kind for short SQLSTATE, got %q", got)
	}
}

func TestDriverErrorStringFormatting(t *testing.T) {
	err := &Error{Message: "boom", SQLState: "42P01"}
	if got, want := err.Error(), "boom (42P01)"; got != want {
		t.Fatalf("formatted error mismatch: got %q want %q", got, want)
	}

	err = &Error{Message: "boom"}
	if got, want := err.Error(), "boom"; got != want {
		t.Fatalf("plain error mismatch: got %q want %q", got, want)
	}

	var nilErr *Error
	if got := nilErr.Error(); got != "" {
		t.Fatalf("nil error string mismatch: got %q", got)
	}
}
