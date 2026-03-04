// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
package scratchbird

import (
	"encoding/binary"
	"reflect"
	"strings"
	"testing"
	"time"
)

func TestEncodeParamRepresentativeValues(t *testing.T) {
	boolParam, boolOID, err := encodeParam(true)
	if err != nil {
		t.Fatalf("encode bool failed: %v", err)
	}
	if boolOID != oidBool {
		t.Fatalf("bool oid mismatch: got %d want %d", boolOID, oidBool)
	}
	if boolParam.null || len(boolParam.data) != 1 || boolParam.data[0] != 1 {
		t.Fatalf("bool encoding mismatch: %#v", boolParam)
	}

	intParam, intOID, err := encodeParam(int32(42))
	if err != nil {
		t.Fatalf("encode int32 failed: %v", err)
	}
	if intOID != oidInt4 {
		t.Fatalf("int32 oid mismatch: got %d want %d", intOID, oidInt4)
	}
	if got := int32(binary.LittleEndian.Uint32(intParam.data)); got != 42 {
		t.Fatalf("int32 payload mismatch: got %d want 42", got)
	}

	jsonbParam, jsonbOID, err := encodeParam(JSONB{Value: map[string]any{"k": 1}})
	if err != nil {
		t.Fatalf("encode jsonb failed: %v", err)
	}
	if jsonbOID != oidJSONB {
		t.Fatalf("jsonb oid mismatch: got %d want %d", jsonbOID, oidJSONB)
	}
	decodedJSONBAny, err := decodeBinaryValue(oidJSONB, jsonbParam.data)
	if err != nil {
		t.Fatalf("decode jsonb failed: %v", err)
	}
	decodedJSONB, ok := decodedJSONBAny.(JSONB)
	if !ok {
		t.Fatalf("decoded jsonb type mismatch: %T", decodedJSONBAny)
	}
	if got := string(decodedJSONB.Raw); got != `{"k":1}` {
		t.Fatalf("jsonb payload mismatch: got %q", got)
	}

	rangeParam, rangeOID, err := encodeParam(Range[int64]{Lower: 10, Upper: 20})
	if err != nil {
		t.Fatalf("encode int8 range failed: %v", err)
	}
	if rangeOID != oidInt8Range {
		t.Fatalf("range oid mismatch: got %d want %d", rangeOID, oidInt8Range)
	}
	decodedRangeAny, err := decodeBinaryValue(oidInt8Range, rangeParam.data)
	if err != nil {
		t.Fatalf("decode range failed: %v", err)
	}
	decodedRange, ok := decodedRangeAny.(Range[any])
	if !ok {
		t.Fatalf("decoded range type mismatch: %T", decodedRangeAny)
	}
	if got, ok := decodedRange.Lower.(int64); !ok || got != 10 {
		t.Fatalf("range lower mismatch: %#v", decodedRange.Lower)
	}
	if got, ok := decodedRange.Upper.(int64); !ok || got != 20 {
		t.Fatalf("range upper mismatch: %#v", decodedRange.Upper)
	}

	compositeParam, compositeOID, err := encodeParam(Composite{
		Fields: []CompositeField{{OID: oidInt4, Value: int32(7)}},
	})
	if err != nil {
		t.Fatalf("encode composite failed: %v", err)
	}
	if compositeOID != oidRecord {
		t.Fatalf("composite oid mismatch: got %d want %d", compositeOID, oidRecord)
	}
	decodedCompositeAny, err := decodeBinaryValue(oidRecord, compositeParam.data)
	if err != nil {
		t.Fatalf("decode composite failed: %v", err)
	}
	decodedComposite, ok := decodedCompositeAny.(Composite)
	if !ok {
		t.Fatalf("decoded composite type mismatch: %T", decodedCompositeAny)
	}
	if len(decodedComposite.Fields) != 1 {
		t.Fatalf("composite field count mismatch: got %d", len(decodedComposite.Fields))
	}
	if got, ok := decodedComposite.Fields[0].Value.(int32); !ok || got != 7 {
		t.Fatalf("composite field value mismatch: %#v", decodedComposite.Fields[0].Value)
	}

	vectorParam, vectorOID, err := encodeParam([]float32{1, 2.5})
	if err != nil {
		t.Fatalf("encode vector failed: %v", err)
	}
	if vectorOID != oidSBVector {
		t.Fatalf("vector oid mismatch: got %d want %d", vectorOID, oidSBVector)
	}
	if got := string(stripLengthPrefix(vectorParam.data)); got != "[1,2.5]" {
		t.Fatalf("vector payload mismatch: got %q", got)
	}
}

func TestEncodeParamRejectsInvalidInputs(t *testing.T) {
	if _, _, err := encodeParam(JSONB{}); err == nil || !strings.Contains(err.Error(), "JSONB requires raw payload") {
		t.Fatalf("expected JSONB raw payload error, got %v", err)
	}
	if _, _, err := encodeParam(Geometry{}); err == nil || !strings.Contains(err.Error(), "geometry requires WKB payload") {
		t.Fatalf("expected geometry WKB error, got %v", err)
	}

	type unsupported struct{}
	if _, _, err := encodeParam(unsupported{}); err == nil || !strings.Contains(err.Error(), "unsupported parameter type") {
		t.Fatalf("expected unsupported parameter type error, got %v", err)
	}
}

func TestDecodeBinaryValueRepresentativeTypes(t *testing.T) {
	numericAny, err := decodeBinaryValue(oidNumeric, encodeLengthPrefixed([]byte("12.34")))
	if err != nil {
		t.Fatalf("decode numeric failed: %v", err)
	}
	if got, ok := numericAny.(string); !ok || got != "12.34" {
		t.Fatalf("numeric mismatch: %#v", numericAny)
	}

	moneyBuf := make([]byte, 8)
	binary.LittleEndian.PutUint64(moneyBuf, uint64(12345))
	moneyAny, err := decodeBinaryValue(oidMoney, moneyBuf)
	if err != nil {
		t.Fatalf("decode money failed: %v", err)
	}
	if got, ok := moneyAny.(int64); !ok || got != 12345 {
		t.Fatalf("money mismatch: %#v", moneyAny)
	}

	uuidBytes := []byte{
		0x00, 0x11, 0x22, 0x33,
		0x44, 0x55,
		0x66, 0x77,
		0x88, 0x99,
		0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff,
	}
	uuidAny, err := decodeBinaryValue(oidUUID, uuidBytes)
	if err != nil {
		t.Fatalf("decode uuid failed: %v", err)
	}
	if got, ok := uuidAny.(string); !ok || got != "00112233-4455-6677-8899-aabbccddeeff" {
		t.Fatalf("uuid mismatch: %#v", uuidAny)
	}

	byteaPayload := encodeLengthPrefixed([]byte{1, 2, 3})
	byteaAny, err := decodeBinaryValue(oidBytea, byteaPayload)
	if err != nil {
		t.Fatalf("decode bytea failed: %v", err)
	}
	bytea, ok := byteaAny.([]byte)
	if !ok {
		t.Fatalf("bytea type mismatch: %T", byteaAny)
	}
	bytea[0] = 9
	if got := stripLengthPrefix(byteaPayload)[0]; got != 1 {
		t.Fatalf("bytea decode should return copy, saw source mutation: %d", got)
	}

	vectorAny, err := decodeBinaryValue(oidSBVector, encodeLengthPrefixed([]byte("[0.5,1.5,2.5]")))
	if err != nil {
		t.Fatalf("decode vector failed: %v", err)
	}
	vector, ok := vectorAny.([]float32)
	if !ok {
		t.Fatalf("vector type mismatch: %T", vectorAny)
	}
	if !reflect.DeepEqual(vector, []float32{0.5, 1.5, 2.5}) {
		t.Fatalf("vector value mismatch: %#v", vector)
	}
}

func TestDecodeColumnValueUnknownTypeHeuristics(t *testing.T) {
	textCol := columnInfo{typeOID: 0, format: uint8(formatText)}
	parsedIntAny, err := decodeColumnValue(textCol, []byte("42"))
	if err != nil {
		t.Fatalf("decode unknown text int failed: %v", err)
	}
	if got, ok := parsedIntAny.(int32); !ok || got != 42 {
		t.Fatalf("unknown text int mismatch: %#v", parsedIntAny)
	}

	parsedBoolAny, err := decodeColumnValue(textCol, []byte("true"))
	if err != nil {
		t.Fatalf("decode unknown text bool failed: %v", err)
	}
	if got, ok := parsedBoolAny.(bool); !ok || !got {
		t.Fatalf("unknown text bool mismatch: %#v", parsedBoolAny)
	}

	binaryCol := columnInfo{typeOID: 0, format: uint8(formatBinary)}
	parsedArrayAny, err := decodeColumnValue(binaryCol, encodeLengthPrefixed([]byte("{1,2,3}")))
	if err != nil {
		t.Fatalf("decode unknown binary array failed: %v", err)
	}
	if !reflect.DeepEqual(parsedArrayAny, []any{1, 2, 3}) {
		t.Fatalf("unknown binary array mismatch: %#v", parsedArrayAny)
	}
}

func TestTypeMetadataHelpers(t *testing.T) {
	if got := oidName(oidSBVector); got != "vector" {
		t.Fatalf("oidName vector mismatch: %q", got)
	}
	if got := oidName(424242); got != "unknown" {
		t.Fatalf("oidName unknown mismatch: %q", got)
	}
	if got := scanTypeForOID(oidTime); got != reflect.TypeOf(time.Duration(0)) {
		t.Fatalf("scan type time mismatch: %v", got)
	}
	if got := scanTypeForOID(oidJSONB); got != reflect.TypeOf(JSONB{}) {
		t.Fatalf("scan type jsonb mismatch: %v", got)
	}
	if got := scanTypeForOID(999999); got != reflect.TypeOf("") {
		t.Fatalf("scan type default mismatch: %v", got)
	}
}
