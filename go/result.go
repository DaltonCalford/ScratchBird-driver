// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
package scratchbird

import "errors"

type Result struct {
	tag          string
	rowsAffected int64
	lastInsertID int64
}

func (r *Result) LastInsertId() (int64, error) {
	if r == nil {
		return 0, errors.New("no result")
	}
	if r.lastInsertID == 0 {
		return 0, errors.New("LastInsertId not available")
	}
	return r.lastInsertID, nil
}

func (r *Result) RowsAffected() (int64, error) {
	if r == nil {
		return 0, errors.New("no result")
	}
	return r.rowsAffected, nil
}
