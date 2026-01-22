package scratchbird

import "database/sql/driver"

func namedValues(values []driver.Value) []driver.NamedValue {
	if len(values) == 0 {
		return nil
	}
	out := make([]driver.NamedValue, len(values))
	for i, value := range values {
		out[i] = driver.NamedValue{Ordinal: i + 1, Value: value}
	}
	return out
}
