// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
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
