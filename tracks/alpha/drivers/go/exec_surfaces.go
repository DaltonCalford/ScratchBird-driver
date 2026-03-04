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
	"database/sql/driver"
	"errors"
	"io"
)

type FieldSummary struct {
	Name     string
	TypeOID  uint32
	Format   uint16
	Nullable bool
}

type ResultSetSummary struct {
	Rows         [][]driver.Value
	RowCount     int64
	Fields       []FieldSummary
	Command      string
	LastInsertID int64
}

type BatchItemSummary struct {
	Index        int
	RowCount     int64
	Fields       []FieldSummary
	Command      string
	LastInsertID int64
}

type BatchSummary struct {
	Items         []BatchItemSummary
	TotalRowCount int64
}

func (c *Conn) NativeSQL(query string, args []driver.NamedValue) (string, error) {
	normalized, err := normalizeQuery(query, args)
	if err != nil {
		return "", normalizeSurfaceError(err)
	}
	return normalized.sql, nil
}

func (c *Conn) NativeCallableSQL(query string, args []driver.NamedValue) (string, error) {
	normalized, err := normalizeCallableQuery(query, args)
	if err != nil {
		return "", normalizeSurfaceError(err)
	}
	return normalized.sql, nil
}

func (c *Conn) CallContext(ctx context.Context, query string, args []driver.NamedValue) (driver.Rows, error) {
	normalized, err := normalizeCallableQuery(query, args)
	if err != nil {
		return nil, normalizeSurfaceError(err)
	}
	return c.QueryContext(ctx, normalized.sql, normalized.args)
}

func (c *Conn) QueryMultiContext(ctx context.Context, query string, args []driver.NamedValue) ([]ResultSetSummary, error) {
	rowsIface, err := c.QueryContext(ctx, query, args)
	if err != nil {
		return nil, err
	}
	rows, ok := rowsIface.(*Rows)
	if !ok {
		_ = rowsIface.Close()
		return nil, &Error{Kind: ErrInternal, Message: "unexpected rows implementation", SQLState: "XX000"}
	}
	defer func() { _ = rows.Close() }()

	summaries := make([]ResultSetSummary, 0, 1)
	for {
		fields := summarizeFields(rows.columns)
		dataRows := make([][]driver.Value, 0)
		for {
			dest := make([]driver.Value, len(rows.columns))
			err := rows.Next(dest)
			if err == nil {
				row := make([]driver.Value, len(dest))
				copy(row, dest)
				dataRows = append(dataRows, row)
				continue
			}
			if errors.Is(err, io.EOF) {
				break
			}
			return nil, err
		}
		summaries = append(summaries, ResultSetSummary{
			Rows:         dataRows,
			RowCount:     rows.rowsAffected,
			Fields:       fields,
			Command:      rows.commandTag,
			LastInsertID: rows.lastInsertID,
		})
		if !rows.HasNextResultSet() {
			break
		}
		if err := rows.NextResultSet(); err != nil {
			if errors.Is(err, io.EOF) {
				break
			}
			return nil, err
		}
	}
	return summaries, nil
}

func (c *Conn) ExecuteMultiContext(ctx context.Context, query string, args []driver.NamedValue) ([]ResultSetSummary, error) {
	return c.QueryMultiContext(ctx, query, args)
}

func (c *Conn) ExecuteBatchContext(ctx context.Context, query string, batchArgs [][]driver.NamedValue) (BatchSummary, error) {
	if batchArgs == nil {
		return BatchSummary{}, &Error{Kind: ErrSyntax, Message: "batch arguments are required", SQLState: "07001"}
	}
	summary := BatchSummary{
		Items: make([]BatchItemSummary, 0, len(batchArgs)),
	}
	for index, args := range batchArgs {
		result, err := c.ExecContext(ctx, query, args)
		if err != nil {
			return summary, err
		}
		rowCount, err := result.RowsAffected()
		if err != nil {
			rowCount = -1
		}
		lastInsertID := int64(0)
		if value, err := result.LastInsertId(); err == nil {
			lastInsertID = value
		}
		command := ""
		if typedResult, ok := result.(*Result); ok {
			command = typedResult.tag
		}
		if rowCount > 0 {
			summary.TotalRowCount += rowCount
		}
		summary.Items = append(summary.Items, BatchItemSummary{
			Index:        index,
			RowCount:     rowCount,
			Fields:       nil,
			Command:      command,
			LastInsertID: lastInsertID,
		})
	}
	return summary, nil
}

func (c *Conn) QueryBatchContext(ctx context.Context, query string, batchArgs [][]driver.NamedValue) (BatchSummary, error) {
	return c.ExecuteBatchContext(ctx, query, batchArgs)
}

func (c *Conn) ExecuteWithGeneratedKeysContext(ctx context.Context, query string, args []driver.NamedValue) ([]int64, error) {
	sets, err := c.QueryMultiContext(ctx, query, args)
	if err != nil {
		return nil, err
	}
	keys := make([]int64, 0, len(sets))
	for _, set := range sets {
		if set.LastInsertID != 0 {
			keys = append(keys, set.LastInsertID)
		}
	}
	return keys, nil
}

func summarizeFields(columns []columnInfo) []FieldSummary {
	if len(columns) == 0 {
		return nil
	}
	out := make([]FieldSummary, 0, len(columns))
	for _, col := range columns {
		out = append(out, FieldSummary{
			Name:     col.name,
			TypeOID:  col.typeOID,
			Format:   uint16(col.format),
			Nullable: col.nullable,
		})
	}
	return out
}

func normalizeSurfaceError(err error) error {
	if err == nil {
		return nil
	}
	if _, ok := err.(*Error); ok {
		return err
	}
	return &Error{Kind: ErrSyntax, Message: err.Error(), SQLState: "07001"}
}
