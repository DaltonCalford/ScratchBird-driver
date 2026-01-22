use std::str;

use bigdecimal::BigDecimal;
use chrono::{DateTime, NaiveDate, NaiveDateTime, NaiveTime, TimeZone, Utc};
use serde_json::Value as JsonValue;

use crate::errors::{Error, ErrorKind, Result};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum WireType {
    Bool = 0x01,
    Int16 = 0x02,
    Int32 = 0x03,
    Int64 = 0x04,
    Float32 = 0x05,
    Float64 = 0x06,
    Decimal = 0x07,
    Varchar = 0x08,
    Char = 0x09,
    Bytea = 0x0A,
    Date = 0x0B,
    Time = 0x0C,
    Timestamp = 0x0D,
    TimestampTz = 0x0E,
    Interval = 0x0F,
    Uuid = 0x10,
    Json = 0x11,
    Jsonb = 0x12,
    Array = 0x13,
    Vector = 0x16,
    Money = 0x17,
    Xml = 0x18,
    Inet = 0x19,
    Cidr = 0x1A,
    TsVector = 0x1C,
    TsQuery = 0x1D,
    Unknown = 0xFF,
}

#[derive(Debug, Clone)]
pub struct Column {
    pub name: String,
    pub wire_type: WireType,
    pub type_modifier: u32,
    pub format: u16,
}

#[derive(Debug, Clone)]
pub struct Interval {
    pub months: i32,
    pub days: i32,
    pub micros: i64,
}

#[derive(Debug, Clone)]
pub enum Value {
    Null,
    Bool(bool),
    Int16(i16),
    Int32(i32),
    Int64(i64),
    Float32(f32),
    Float64(f64),
    Decimal(BigDecimal),
    String(String),
    Bytes(Vec<u8>),
    Date(NaiveDate),
    Time(NaiveTime),
    Timestamp(DateTime<Utc>),
    Interval(Interval),
    Uuid(String),
    Json(JsonValue),
    Array(Vec<Value>),
    Vector(Vec<f64>),
}

pub fn decode_value(wire_type: u8, data: Option<Vec<u8>>) -> Result<Value> {
    let Some(data) = data else {
        return Ok(Value::Null);
    };
    match wire_type {
        x if x == WireType::Bool as u8 => Ok(Value::Bool(data.get(0).copied().unwrap_or(0) == 1)),
        x if x == WireType::Int16 as u8 => Ok(Value::Int16(i16::from_le_bytes([data[0], data[1]]))),
        x if x == WireType::Int32 as u8 => Ok(Value::Int32(i32::from_le_bytes([data[0], data[1], data[2], data[3]]))),
        x if x == WireType::Int64 as u8 => Ok(Value::Int64(i64::from_le_bytes(data[..8].try_into().unwrap_or([0u8; 8])))),
        x if x == WireType::Float32 as u8 => Ok(Value::Float32(f32::from_le_bytes(data[..4].try_into().unwrap_or([0u8; 4])))),
        x if x == WireType::Float64 as u8 => Ok(Value::Float64(f64::from_le_bytes(data[..8].try_into().unwrap_or([0u8; 8])))),
        x if x == WireType::Decimal as u8 => {
            let text = str::from_utf8(&data).unwrap_or("0");
            Ok(Value::Decimal(text.parse::<BigDecimal>().unwrap_or_else(|_| BigDecimal::from(0))))
        }
        x if x == WireType::Varchar as u8
            || x == WireType::Char as u8
            || x == WireType::Xml as u8
            || x == WireType::TsVector as u8
            || x == WireType::TsQuery as u8 =>
        {
            Ok(Value::String(String::from_utf8_lossy(&data).to_string()))
        }
        x if x == WireType::Bytea as u8 => Ok(Value::Bytes(data)),
        x if x == WireType::Date as u8 => {
            let days = i32::from_le_bytes(data[..4].try_into().unwrap_or([0u8; 4]));
            let base = NaiveDate::from_ymd_opt(2000, 1, 1).unwrap();
            let date = if days >= 0 {
                base.checked_add_days(chrono::Days::new(days as u64)).unwrap_or(base)
            } else {
                base.checked_sub_days(chrono::Days::new((-days) as u64)).unwrap_or(base)
            };
            Ok(Value::Date(date))
        }
        x if x == WireType::Time as u8 => {
            let micros = i64::from_le_bytes(data[..8].try_into().unwrap_or([0u8; 8]));
            let secs = micros / 1_000_000;
            let nsecs = (micros % 1_000_000) * 1000;
            let time = NaiveTime::from_num_seconds_from_midnight_opt(secs as u32, nsecs as u32)
                .unwrap_or_else(|| NaiveTime::from_hms_opt(0, 0, 0).unwrap());
            Ok(Value::Time(time))
        }
        x if x == WireType::Timestamp as u8 || x == WireType::TimestampTz as u8 => {
            let micros = i64::from_le_bytes(data[..8].try_into().unwrap_or([0u8; 8]));
            let secs = micros / 1_000_000;
            let nsecs = (micros % 1_000_000) * 1000;
            let dt = NaiveDateTime::from_timestamp_opt(secs, nsecs as u32)
                .ok_or_else(|| Error::new(ErrorKind::Data, "invalid timestamp"))?;
            Ok(Value::Timestamp(DateTime::<Utc>::from_utc(dt, Utc)))
        }
        x if x == WireType::Interval as u8 => {
            let months = i32::from_le_bytes(data[..4].try_into().unwrap_or([0u8; 4]));
            let days = i32::from_le_bytes(data[4..8].try_into().unwrap_or([0u8; 4]));
            let micros = i64::from_le_bytes(data[8..16].try_into().unwrap_or([0u8; 8]));
            Ok(Value::Interval(Interval { months, days, micros }))
        }
        x if x == WireType::Uuid as u8 => Ok(Value::Uuid(bytes_to_uuid(&data))),
        x if x == WireType::Json as u8 || x == WireType::Jsonb as u8 => {
            let text = str::from_utf8(&data).unwrap_or("{}");
            let json = serde_json::from_str::<JsonValue>(text).unwrap_or(JsonValue::String(text.to_string()));
            Ok(Value::Json(json))
        }
        x if x == WireType::Array as u8 => {
            let text = String::from_utf8_lossy(&data).to_string();
            Ok(Value::Array(parse_array_literal(&text)))
        }
        x if x == WireType::Vector as u8 => {
            let text = String::from_utf8_lossy(&data).to_string();
            Ok(Value::Vector(parse_vector_literal(&text)))
        }
        x if x == WireType::Money as u8 => {
            let cents = i64::from_le_bytes(data[..8].try_into().unwrap_or([0u8; 8]));
            let mut dec = BigDecimal::from(cents);
            dec /= BigDecimal::from(100);
            Ok(Value::Decimal(dec))
        }
        x if x == WireType::Inet as u8 || x == WireType::Cidr as u8 => {
            Ok(Value::String(String::from_utf8_lossy(&data).to_string()))
        }
        _ => Ok(Value::Bytes(data)),
    }
}

fn bytes_to_uuid(data: &[u8]) -> String {
    let hex = data.iter().map(|b| format!("{:02x}", b)).collect::<String>();
    if hex.len() == 32 {
        format!(
            "{}-{}-{}-{}-{}",
            &hex[0..8],
            &hex[8..12],
            &hex[12..16],
            &hex[16..20],
            &hex[20..32]
        )
    } else {
        hex
    }
}

fn parse_array_literal(text: &str) -> Vec<Value> {
    let trimmed = text.trim();
    if trimmed.is_empty() || trimmed == "{}" {
        return Vec::new();
    }
    let inner = trimmed.strip_prefix('{').and_then(|s| s.strip_suffix('}')).unwrap_or(trimmed);
    split_array_items(inner)
}

fn split_array_items(text: &str) -> Vec<Value> {
    let mut items = Vec::new();
    let mut depth = 0i32;
    let mut buffer = String::new();
    for ch in text.chars() {
        match ch {
            '{' => {
                depth += 1;
                buffer.push(ch);
            }
            '}' => {
                depth -= 1;
                buffer.push(ch);
            }
            ',' if depth == 0 => {
                items.push(parse_array_item(&buffer));
                buffer.clear();
            }
            _ => buffer.push(ch),
        }
    }
    if !buffer.is_empty() || !text.is_empty() {
        items.push(parse_array_item(&buffer));
    }
    items
}

fn parse_array_item(raw: &str) -> Value {
    let token = raw.trim();
    if token.eq_ignore_ascii_case("NULL") {
        return Value::Null;
    }
    if token.starts_with('{') && token.ends_with('}') {
        return Value::Array(parse_array_literal(token));
    }
    if token.starts_with('[') && token.ends_with(']') {
        return Value::Vector(parse_vector_literal(token));
    }
    if token.eq_ignore_ascii_case("true") {
        return Value::Bool(true);
    }
    if token.eq_ignore_ascii_case("false") {
        return Value::Bool(false);
    }
    if let Ok(val) = token.parse::<i64>() {
        return Value::Int64(val);
    }
    if let Ok(val) = token.parse::<f64>() {
        return Value::Float64(val);
    }
    Value::String(token.to_string())
}

fn parse_vector_literal(text: &str) -> Vec<f64> {
    let trimmed = text.trim();
    let inner = trimmed.strip_prefix('[').and_then(|s| s.strip_suffix(']')).unwrap_or(trimmed);
    if inner.is_empty() {
        return Vec::new();
    }
    inner
        .split(',')
        .filter_map(|item| item.trim().parse::<f64>().ok())
        .collect()
}
