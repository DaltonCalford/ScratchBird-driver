package scratchbird

import (
	"database/sql/driver"
	"io"
	"reflect"
)

type Rows struct {
	conn         *Conn
	columns      []columnInfo
	rowCountHint int64
	rowsAffected int64
	commandTag   string
	done         bool
}

func (r *Rows) Columns() []string {
	names := make([]string, len(r.columns))
	for i, col := range r.columns {
		names[i] = col.name
	}
	return names
}

func (r *Rows) Close() error {
	if r.done {
		return nil
	}
	for !r.done {
		if _, err := r.nextRow(); err != nil {
			if err == io.EOF {
				break
			}
			return err
		}
	}
	return nil
}

func (r *Rows) Next(dest []driver.Value) error {
	row, err := r.nextRow()
	if err != nil {
		return err
	}
	for i := range dest {
		if i < len(row) {
			dest[i] = row[i]
		} else {
			dest[i] = nil
		}
	}
	return nil
}

func (r *Rows) nextRow() ([]driver.Value, error) {
	if r.done {
		return nil, io.EOF
	}
	for {
		msg, err := r.conn.receive()
		if err != nil {
			return nil, err
		}
		switch msg.typ {
		case msgQueryError:
			return nil, buildQueryError(msg.body)
		case msgQueryResult:
			_, _, rows, err := parseQueryResult(msg.body)
			if err != nil {
				return nil, err
			}
			r.rowCountHint = rows
		case msgRowDescription:
			cols, err := parseRowDescription(msg.body)
			if err != nil {
				return nil, err
			}
			r.columns = cols
		case msgRowData:
			values, err := parseRowData(msg.body)
			if err != nil {
				return nil, err
			}
			out := make([]driver.Value, len(values))
			for i, value := range values {
				if value.null {
					out[i] = nil
				} else {
					typ := wireUnknown
					if i < len(r.columns) {
						typ = r.columns[i].wireType
					}
					out[i] = decodeValue(typ, value.data)
				}
			}
			return out, nil
		case msgCommandComplete:
			tag, rows, err := parseCommandComplete(msg.body)
			if err != nil {
				return nil, err
			}
			r.commandTag = tag
			r.rowsAffected = rows
		case msgEndResults:
			r.done = true
			return nil, io.EOF
		}
	}
}

func (r *Rows) ColumnTypeDatabaseTypeName(index int) string {
	if index < 0 || index >= len(r.columns) {
		return ""
	}
	return wireTypeName(r.columns[index].wireType)
}

func (r *Rows) ColumnTypeNullable(index int) (nullable, ok bool) {
	return true, true
}

func (r *Rows) ColumnTypeLength(index int) (length int64, ok bool) {
	if index < 0 || index >= len(r.columns) {
		return 0, false
	}
	return int64(r.columns[index].typeModifier), true
}

func (r *Rows) ColumnTypePrecisionScale(index int) (precision, scale int64, ok bool) {
	return 0, 0, false
}

func (r *Rows) ColumnTypeScanType(index int) reflect.Type {
	if index < 0 || index >= len(r.columns) {
		return nil
	}
	return scanTypeForWire(r.columns[index].wireType)
}
