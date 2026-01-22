package scratchbird

import (
	"encoding/binary"
	"encoding/hex"
	"math"
	"reflect"
	"strconv"
	"strings"
	"time"
)

func decodeValue(typ wireType, data []byte) interface{} {
	if data == nil {
		return nil
	}
	switch typ {
	case wireBool:
		return len(data) > 0 && data[0] == 1
	case wireInt16:
		return int16(binary.LittleEndian.Uint16(data))
	case wireInt32:
		return int32(binary.LittleEndian.Uint32(data))
	case wireInt64:
		return int64(binary.LittleEndian.Uint64(data))
	case wireFloat32:
		return math.Float32frombits(binary.LittleEndian.Uint32(data))
	case wireFloat64:
		return math.Float64frombits(binary.LittleEndian.Uint64(data))
	case wireDecimal:
		return string(data)
	case wireVarchar, wireChar, wireJSON, wireJSONB, wireXML, wireTsvector, wireTsquery:
		return string(data)
	case wireBytea:
		return append([]byte{}, data...)
	case wireDate:
		days := int32(binary.LittleEndian.Uint32(data))
		base := time.Date(2000, 1, 1, 0, 0, 0, 0, time.UTC)
		return base.AddDate(0, 0, int(days))
	case wireTime:
		micros := int64(binary.LittleEndian.Uint64(data))
		return time.Duration(micros) * time.Microsecond
	case wireTimestamp:
		micros := int64(binary.LittleEndian.Uint64(data))
		return time.Unix(0, micros*1000).UTC()
	case wireTimestamptz:
		micros := int64(binary.LittleEndian.Uint64(data))
		return time.Unix(0, micros*1000).UTC()
	case wireInterval:
		months := int32(binary.LittleEndian.Uint32(data[0:4]))
		days := int32(binary.LittleEndian.Uint32(data[4:8]))
		micros := int64(binary.LittleEndian.Uint64(data[8:16]))
		return map[string]interface{}{
			"months": months,
			"days":   days,
			"micros": micros,
		}
	case wireUUID:
		return bytesToUUIDString(data)
	case wireMoney:
		cents := int64(binary.LittleEndian.Uint64(data))
		return float64(cents) / 100.0
	case wireInet, wireCidr:
		return string(data)
	case wireArray:
		return parseArrayLiteral(string(data))
	case wireVector:
		return parseVectorLiteral(string(data))
	default:
		return append([]byte{}, data...)
	}
}

func bytesToUUIDString(data []byte) string {
	if len(data) != 16 {
		return hex.EncodeToString(data)
	}
	hexStr := hex.EncodeToString(data)
	return hexStr[0:8] + "-" + hexStr[8:12] + "-" + hexStr[12:16] + "-" + hexStr[16:20] + "-" + hexStr[20:]
}

func parseArrayLiteral(text string) []interface{} {
	trimmed := strings.TrimSpace(text)
	if trimmed == "" || trimmed == "{}" {
		return []interface{}{}
	}
	if strings.HasPrefix(trimmed, "{") && strings.HasSuffix(trimmed, "}") {
		trimmed = trimmed[1 : len(trimmed)-1]
	}
	return splitArrayItems(trimmed)
}

func splitArrayItems(text string) []interface{} {
	var items []interface{}
	depth := 0
	var sb strings.Builder
	for _, ch := range text {
		switch ch {
		case '{':
			depth++
			sb.WriteRune(ch)
		case '}':
			if depth > 0 {
				depth--
			}
			sb.WriteRune(ch)
		case ',':
			if depth == 0 {
				items = append(items, parseArrayItem(sb.String()))
				sb.Reset()
			} else {
				sb.WriteRune(ch)
			}
		default:
			sb.WriteRune(ch)
		}
	}
	if sb.Len() > 0 || text != "" {
		items = append(items, parseArrayItem(sb.String()))
	}
	return items
}

func parseArrayItem(raw string) interface{} {
	token := strings.TrimSpace(raw)
	if strings.EqualFold(token, "NULL") {
		return nil
	}
	if strings.HasPrefix(token, "{") && strings.HasSuffix(token, "}") {
		return parseArrayLiteral(token)
	}
	if strings.HasPrefix(token, "[") && strings.HasSuffix(token, "]") {
		return parseVectorLiteral(token)
	}
	if token == "" {
		return ""
	}
	if token == "true" || token == "false" {
		return token == "true"
	}
	if i, err := strconv.Atoi(token); err == nil {
		return i
	}
	if f, err := strconv.ParseFloat(token, 64); err == nil {
		return f
	}
	return token
}

func parseVectorLiteral(text string) []float32 {
	trimmed := strings.TrimSpace(text)
	if strings.HasPrefix(trimmed, "[") && strings.HasSuffix(trimmed, "]") {
		trimmed = trimmed[1 : len(trimmed)-1]
	}
	if trimmed == "" {
		return []float32{}
	}
	parts := strings.Split(trimmed, ",")
	out := make([]float32, 0, len(parts))
	for _, part := range parts {
		val, err := strconv.ParseFloat(strings.TrimSpace(part), 32)
		if err != nil {
			out = append(out, 0)
		} else {
			out = append(out, float32(val))
		}
	}
	return out
}

func wireTypeName(typ wireType) string {
	switch typ {
	case wireBool:
		return "boolean"
	case wireInt16:
		return "int16"
	case wireInt32:
		return "int32"
	case wireInt64:
		return "int64"
	case wireFloat32:
		return "float32"
	case wireFloat64:
		return "float64"
	case wireDecimal:
		return "decimal"
	case wireVarchar:
		return "varchar"
	case wireChar:
		return "char"
	case wireBytea:
		return "bytea"
	case wireDate:
		return "date"
	case wireTime:
		return "time"
	case wireTimestamp:
		return "timestamp"
	case wireTimestamptz:
		return "timestamptz"
	case wireInterval:
		return "interval"
	case wireUUID:
		return "uuid"
	case wireJSON:
		return "json"
	case wireJSONB:
		return "jsonb"
	case wireArray:
		return "array"
	case wireComposite:
		return "composite"
	case wireGeometry:
		return "geometry"
	case wireVector:
		return "vector"
	case wireMoney:
		return "money"
	case wireXML:
		return "xml"
	case wireInet:
		return "inet"
	case wireCidr:
		return "cidr"
	case wireMacaddr:
		return "macaddr"
	case wireTsvector:
		return "tsvector"
	case wireTsquery:
		return "tsquery"
	case wireRange:
		return "range"
	default:
		return "unknown"
	}
}

func scanTypeForWire(typ wireType) reflect.Type {
	switch typ {
	case wireBool:
		return reflect.TypeOf(false)
	case wireInt16:
		return reflect.TypeOf(int16(0))
	case wireInt32:
		return reflect.TypeOf(int32(0))
	case wireInt64:
		return reflect.TypeOf(int64(0))
	case wireFloat32:
		return reflect.TypeOf(float32(0))
	case wireFloat64:
		return reflect.TypeOf(float64(0))
	case wireDecimal:
		return reflect.TypeOf("")
	case wireVarchar, wireChar, wireJSON, wireJSONB, wireXML, wireTsvector, wireTsquery:
		return reflect.TypeOf("")
	case wireBytea:
		return reflect.TypeOf([]byte{})
	case wireDate, wireTimestamp, wireTimestamptz:
		return reflect.TypeOf(time.Time{})
	case wireTime:
		return reflect.TypeOf(time.Duration(0))
	case wireInterval:
		return reflect.TypeOf(map[string]interface{}{})
	case wireUUID:
		return reflect.TypeOf("")
	case wireMoney:
		return reflect.TypeOf(float64(0))
	case wireArray:
		return reflect.TypeOf([]interface{}{})
	case wireVector:
		return reflect.TypeOf([]float32{})
	default:
		return reflect.TypeOf(new(interface{})).Elem()
	}
}
