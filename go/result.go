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
