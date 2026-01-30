// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
package scratchbird

import "fmt"

type ErrorKind string

const (
	ErrWarning      ErrorKind = "warning"
	ErrNoData       ErrorKind = "no_data"
	ErrConnection   ErrorKind = "connection"
	ErrNotSupported ErrorKind = "not_supported"
	ErrData         ErrorKind = "data"
	ErrIntegrity    ErrorKind = "integrity"
	ErrAuth         ErrorKind = "auth"
	ErrTransaction  ErrorKind = "transaction"
	ErrSyntax       ErrorKind = "syntax"
	ErrResource     ErrorKind = "resource"
	ErrLimit        ErrorKind = "limit"
	ErrOperator     ErrorKind = "operator"
	ErrSystem       ErrorKind = "system"
	ErrInternal     ErrorKind = "internal"
	ErrUnknown      ErrorKind = "unknown"
)

type Error struct {
	Kind     ErrorKind
	Code     uint32
	SQLState string
	Message  string
	Detail   string
	Hint     string
}

func (e *Error) Error() string {
	if e == nil {
		return ""
	}
	if e.SQLState != "" {
		return fmt.Sprintf("%s (%s)", e.Message, e.SQLState)
	}
	return e.Message
}

func mapSQLState(sqlState string) ErrorKind {
	if len(sqlState) < 2 {
		return ErrUnknown
	}
	switch sqlState[:2] {
	case "01":
		return ErrWarning
	case "02":
		return ErrNoData
	case "08":
		return ErrConnection
	case "0A":
		return ErrNotSupported
	case "22":
		return ErrData
	case "23":
		return ErrIntegrity
	case "28":
		return ErrAuth
	case "40":
		return ErrTransaction
	case "42":
		return ErrSyntax
	case "53":
		return ErrResource
	case "54":
		return ErrLimit
	case "57":
		return ErrOperator
	case "58":
		return ErrSystem
	case "XX":
		return ErrInternal
	default:
		return ErrUnknown
	}
}
