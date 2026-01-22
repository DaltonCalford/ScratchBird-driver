use scratchbird::types::decode_value;
use scratchbird::{Value, WireType};

#[test]
fn decode_uuid() {
    let bytes = hex::decode("12345678123456781234567812345678").unwrap();
    let out = decode_value(WireType::Uuid as u8, Some(bytes)).unwrap();
    match out {
        Value::Uuid(text) => assert_eq!(text, "12345678-1234-5678-1234-567812345678"),
        _ => panic!("unexpected value"),
    }
}

#[test]
fn decode_array() {
    let data = b"{1,2,3}".to_vec();
    let out = decode_value(WireType::Array as u8, Some(data)).unwrap();
    match out {
        Value::Array(values) => assert_eq!(values.len(), 3),
        _ => panic!("unexpected value"),
    }
}
