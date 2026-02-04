// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
use scratchbird::types::{decode_value, Jsonb, Value, FORMAT_BINARY, OID_JSONB, OID_SB_VECTOR, OID_UUID};

#[test]
fn decode_uuid() {
    let bytes = hex::decode("12345678123456781234567812345678").unwrap();
    let out = decode_value(OID_UUID, Some(bytes), FORMAT_BINARY).unwrap();
    match out {
        Value::Uuid(text) => assert_eq!(text, "12345678-1234-5678-1234-567812345678"),
        _ => panic!("unexpected value"),
    }
}

#[test]
fn decode_jsonb() {
    let json = b"{\"a\":1}";
    let mut data = Vec::new();
    data.extend_from_slice(&(json.len() as u32).to_le_bytes());
    data.extend_from_slice(json);
    let out = decode_value(OID_JSONB, Some(data), FORMAT_BINARY).unwrap();
    match out {
        Value::Jsonb(Jsonb { raw, .. }) => assert_eq!(raw, json),
        _ => panic!("unexpected value"),
    }
}

#[test]
fn decode_vector() {
    let vector = "[1,2,3]";
    let mut data = Vec::new();
    data.extend_from_slice(&(vector.len() as u32).to_le_bytes());
    data.extend_from_slice(vector.as_bytes());
    let out = decode_value(OID_SB_VECTOR, Some(data), FORMAT_BINARY).unwrap();
    match out {
        Value::Vector(values) => assert_eq!(values, vec![1.0_f32, 2.0, 3.0]),
        _ => panic!("unexpected value"),
    }
}
