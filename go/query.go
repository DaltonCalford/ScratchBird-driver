// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
package scratchbird

import (
	"database/sql/driver"
	"errors"
	"strings"
)

type normalizedQuery struct {
	sql  string
	args []driver.NamedValue
}

func normalizeQuery(query string, args []driver.NamedValue) (normalizedQuery, error) {
	if len(args) == 0 {
		return normalizedQuery{sql: query, args: nil}, nil
	}
	if hasNamedParams(query) {
		sql, ordered, err := rewriteNamedParams(query, args)
		if err != nil {
			return normalizedQuery{}, err
		}
		return normalizedQuery{sql: sql, args: ordered}, nil
	}
	if strings.Contains(query, "?") {
		sql, ordered, err := rewritePositionalParams(query, args)
		if err != nil {
			return normalizedQuery{}, err
		}
		return normalizedQuery{sql: sql, args: ordered}, nil
	}
	return normalizedQuery{sql: query, args: args}, nil
}

func hasNamedParams(query string) bool {
	inString := false
	for i := 0; i+1 < len(query); i++ {
		ch := query[i]
		if ch == '\'' {
			inString = !inString
			continue
		}
		if inString {
			continue
		}
		if (ch == '@' || ch == ':') && isIdentStart(query[i+1]) {
			return true
		}
	}
	return false
}

func rewriteNamedParams(query string, args []driver.NamedValue) (string, []driver.NamedValue, error) {
	lookup := map[string]driver.NamedValue{}
	for _, arg := range args {
		if arg.Name != "" {
			lookup[strings.TrimLeft(arg.Name, "@:")] = arg
		}
	}
	var sb strings.Builder
	ordered := make([]driver.NamedValue, 0, len(args))
	inString := false
	for i := 0; i < len(query); {
		ch := query[i]
		if ch == '\'' {
			inString = !inString
			sb.WriteByte(ch)
			i++
			continue
		}
		if !inString && (ch == '@' || ch == ':') && i+1 < len(query) && isIdentStart(query[i+1]) {
			j := i + 1
			for j < len(query) && isIdentPart(query[j]) {
				j++
			}
			name := query[i+1 : j]
			param, ok := lookup[name]
			if !ok {
				return "", nil, errors.New("missing named parameter: " + name)
			}
			ordered = append(ordered, param)
			sb.WriteString("$")
			sb.WriteString(intToString(len(ordered)))
			i = j
			continue
		}
		sb.WriteByte(ch)
		i++
	}
	return sb.String(), ordered, nil
}

func rewritePositionalParams(query string, args []driver.NamedValue) (string, []driver.NamedValue, error) {
	var sb strings.Builder
	ordered := make([]driver.NamedValue, 0, len(args))
	inString := false
	index := 0
	for i := 0; i < len(query); {
		ch := query[i]
		if ch == '\'' {
			inString = !inString
			sb.WriteByte(ch)
			i++
			continue
		}
		if !inString && ch == '?' {
			if index >= len(args) {
				return "", nil, errors.New("not enough parameters")
			}
			ordered = append(ordered, args[index])
			index++
			sb.WriteString("$")
			sb.WriteString(intToString(len(ordered)))
			i++
			continue
		}
		sb.WriteByte(ch)
		i++
	}
	if index < len(args) {
		return "", nil, errors.New("too many parameters")
	}
	return sb.String(), ordered, nil
}

func intToString(value int) string {
	if value == 0 {
		return "0"
	}
	var buf [20]byte
	pos := len(buf)
	for value > 0 {
		pos--
		buf[pos] = byte('0' + value%10)
		value /= 10
	}
	return string(buf[pos:])
}

func isIdentStart(ch byte) bool {
	return (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || ch == '_'
}

func isIdentPart(ch byte) bool {
	return isIdentStart(ch) || (ch >= '0' && ch <= '9')
}
