package scratchbird

import (
	"database/sql/driver"
	"encoding/hex"
	"fmt"
	"strings"
	"time"
)

func rewriteQuery(query string, args []driver.NamedValue) (string, error) {
	if len(args) == 0 {
		return query, nil
	}
	if hasNamedParams(query) {
		return substituteNamed(query, args), nil
	}
	return substitutePositional(query, args), nil
}

func hasNamedParams(query string) bool {
	for i := 0; i+1 < len(query); i++ {
		ch := query[i]
		if (ch == '@' || ch == ':') && isIdentStart(query[i+1]) {
			return true
		}
	}
	return false
}

func substituteNamed(query string, args []driver.NamedValue) string {
	lookup := map[string]driver.NamedValue{}
	for _, arg := range args {
		if arg.Name != "" {
			lookup[strings.TrimLeft(arg.Name, "@:")] = arg
		}
	}
	var sb strings.Builder
	for i := 0; i < len(query); {
		ch := query[i]
		if ch == '\'' && i+1 < len(query) {
			sb.WriteByte(ch)
			i++
			for i < len(query) {
				sb.WriteByte(query[i])
				if query[i] == '\'' && (i+1 >= len(query) || query[i+1] != '\'') {
					i++
					break
				}
				if query[i] == '\'' && i+1 < len(query) && query[i+1] == '\'' {
					i++
				}
				i++
			}
			continue
		}
		if (ch == '@' || ch == ':') && i+1 < len(query) && isIdentStart(query[i+1]) {
			j := i + 1
			for j < len(query) && isIdentPart(query[j]) {
				j++
			}
			name := query[i+1 : j]
			if param, ok := lookup[name]; ok {
				sb.WriteString(formatValue(param.Value))
			} else {
				sb.WriteString(query[i:j])
			}
			i = j
			continue
		}
		sb.WriteByte(ch)
		i++
	}
	return sb.String()
}

func substitutePositional(query string, args []driver.NamedValue) string {
	var sb strings.Builder
	index := 0
	for i := 0; i < len(query); {
		ch := query[i]
		if ch == '?' {
			if index < len(args) {
				sb.WriteString(formatValue(args[index].Value))
				index++
			} else {
				sb.WriteByte(ch)
			}
			i++
			continue
		}
		if ch == '$' && i+1 < len(query) && isDigit(query[i+1]) {
			j := i + 1
			num := 0
			for j < len(query) && isDigit(query[j]) {
				num = num*10 + int(query[j]-'0')
				j++
			}
			if num > 0 && num <= len(args) {
				sb.WriteString(formatValue(args[num-1].Value))
			} else {
				sb.WriteString(query[i:j])
			}
			i = j
			continue
		}
		if ch == '\'' && i+1 < len(query) {
			sb.WriteByte(ch)
			i++
			for i < len(query) {
				sb.WriteByte(query[i])
				if query[i] == '\'' && (i+1 >= len(query) || query[i+1] != '\'') {
					i++
					break
				}
				if query[i] == '\'' && i+1 < len(query) && query[i+1] == '\'' {
					i++
				}
				i++
			}
			continue
		}
		sb.WriteByte(ch)
		i++
	}
	return sb.String()
}

func formatValue(value interface{}) string {
	if value == nil {
		return "NULL"
	}
	switch v := value.(type) {
	case bool:
		if v {
			return "TRUE"
		}
		return "FALSE"
	case int64:
		return fmt.Sprintf("%d", v)
	case int:
		return fmt.Sprintf("%d", v)
	case int32:
		return fmt.Sprintf("%d", v)
	case int16:
		return fmt.Sprintf("%d", v)
	case int8:
		return fmt.Sprintf("%d", v)
	case uint64:
		return fmt.Sprintf("%d", v)
	case uint:
		return fmt.Sprintf("%d", v)
	case uint32:
		return fmt.Sprintf("%d", v)
	case uint16:
		return fmt.Sprintf("%d", v)
	case uint8:
		return fmt.Sprintf("%d", v)
	case float64:
		return fmt.Sprintf("%g", v)
	case float32:
		return fmt.Sprintf("%g", v)
	case string:
		return "'" + escapeString(v) + "'"
	case []byte:
		return "X'" + hex.EncodeToString(v) + "'"
	case time.Time:
		return "'" + v.UTC().Format("2006-01-02 15:04:05.999999") + "'"
	case fmt.Stringer:
		return "'" + escapeString(v.String()) + "'"
	}
	switch v := value.(type) {
	case []interface{}:
		return formatArray(v)
	}
	return "'" + escapeString(fmt.Sprintf("%v", value)) + "'"
}

func formatArray(values []interface{}) string {
	items := make([]string, 0, len(values))
	for _, v := range values {
		items = append(items, formatValue(v))
	}
	return "ARRAY[" + strings.Join(items, ", ") + "]"
}

func escapeString(value string) string {
	return strings.ReplaceAll(strings.ReplaceAll(value, "\\", "\\\\"), "'", "''")
}

func isIdentStart(ch byte) bool {
	return (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || ch == '_'
}

func isIdentPart(ch byte) bool {
	return isIdentStart(ch) || isDigit(ch)
}

func isDigit(ch byte) bool {
	return ch >= '0' && ch <= '9'
}

func namedValues(args []driver.Value) []driver.NamedValue {
	out := make([]driver.NamedValue, len(args))
	for i, val := range args {
		out[i] = driver.NamedValue{Ordinal: i + 1, Value: val}
	}
	return out
}
