use std::collections::HashMap;

use bigdecimal::BigDecimal;
use chrono::{DateTime, NaiveDate, NaiveTime, Utc};
use serde_json::Value as JsonValue;

#[derive(Debug, Clone)]
pub enum Param {
    Null,
    Bool(bool),
    Int(i64),
    Float(f64),
    Decimal(BigDecimal),
    String(String),
    Bytes(Vec<u8>),
    Date(NaiveDate),
    Time(NaiveTime),
    Timestamp(DateTime<Utc>),
    Json(JsonValue),
    Array(Vec<Param>),
    Inet(String),
    Cidr(String),
    Uuid(String),
}

#[derive(Debug, Clone)]
pub enum Params {
    Positional(Vec<Param>),
    Named(HashMap<String, Param>),
}

impl From<Vec<Param>> for Params {
    fn from(value: Vec<Param>) -> Self {
        Params::Positional(value)
    }
}

impl From<HashMap<String, Param>> for Params {
    fn from(value: HashMap<String, Param>) -> Self {
        Params::Named(value)
    }
}

impl From<()> for Params {
    fn from(_: ()) -> Self {
        Params::Positional(Vec::new())
    }
}

impl From<bool> for Param {
    fn from(value: bool) -> Self {
        Param::Bool(value)
    }
}

impl From<i64> for Param {
    fn from(value: i64) -> Self {
        Param::Int(value)
    }
}

impl From<i32> for Param {
    fn from(value: i32) -> Self {
        Param::Int(value as i64)
    }
}

impl From<i16> for Param {
    fn from(value: i16) -> Self {
        Param::Int(value as i64)
    }
}

impl From<f64> for Param {
    fn from(value: f64) -> Self {
        Param::Float(value)
    }
}

impl From<f32> for Param {
    fn from(value: f32) -> Self {
        Param::Float(value as f64)
    }
}

impl From<&str> for Param {
    fn from(value: &str) -> Self {
        Param::String(value.to_string())
    }
}

impl From<String> for Param {
    fn from(value: String) -> Self {
        Param::String(value)
    }
}

impl From<Vec<u8>> for Param {
    fn from(value: Vec<u8>) -> Self {
        Param::Bytes(value)
    }
}

impl From<&[u8]> for Param {
    fn from(value: &[u8]) -> Self {
        Param::Bytes(value.to_vec())
    }
}

impl From<NaiveDate> for Param {
    fn from(value: NaiveDate) -> Self {
        Param::Date(value)
    }
}

impl From<NaiveTime> for Param {
    fn from(value: NaiveTime) -> Self {
        Param::Time(value)
    }
}

impl From<DateTime<Utc>> for Param {
    fn from(value: DateTime<Utc>) -> Self {
        Param::Timestamp(value)
    }
}

impl From<BigDecimal> for Param {
    fn from(value: BigDecimal) -> Self {
        Param::Decimal(value)
    }
}

impl From<JsonValue> for Param {
    fn from(value: JsonValue) -> Self {
        Param::Json(value)
    }
}

pub fn substitute(sql: &str, params: Params) -> String {
    match params {
        Params::Positional(values) => substitute_positional(sql, &values),
        Params::Named(values) => substitute_named(sql, &values),
    }
}

fn substitute_named(sql: &str, params: &HashMap<String, Param>) -> String {
    let mut out = String::new();
    let mut i = 0;
    let chars: Vec<char> = sql.chars().collect();
    while i < chars.len() {
        let ch = chars[i];
        if ch == '\'' && i + 1 < chars.len() {
            out.push(ch);
            i += 1;
            while i < chars.len() {
                out.push(chars[i]);
                if chars[i] == '\'' && (i + 1 >= chars.len() || chars[i + 1] != '\'') {
                    i += 1;
                    break;
                }
                if chars[i] == '\'' && i + 1 < chars.len() && chars[i + 1] == '\'' {
                    i += 1;
                }
                i += 1;
            }
            continue;
        }
        if (ch == ':' || ch == '@') && i + 1 < chars.len() && chars[i + 1].is_ascii_alphabetic() {
            let mut j = i + 1;
            while j < chars.len() && (chars[j].is_ascii_alphanumeric() || chars[j] == '_') {
                j += 1;
            }
            let name: String = chars[i + 1..j].iter().collect();
            if let Some(val) = params.get(&name) {
                out.push_str(&format_param(val));
            } else {
                out.extend(chars[i..j].iter());
            }
            i = j;
            continue;
        }
        out.push(ch);
        i += 1;
    }
    out
}

fn substitute_positional(sql: &str, params: &[Param]) -> String {
    let mut out = String::new();
    let mut i = 0;
    let mut next_param = 0;
    let chars: Vec<char> = sql.chars().collect();
    while i < chars.len() {
        let ch = chars[i];
        if ch == '$' && i + 1 < chars.len() && chars[i + 1].is_ascii_digit() {
            let mut j = i + 1;
            let mut num = 0usize;
            while j < chars.len() && chars[j].is_ascii_digit() {
                num = num * 10 + chars[j].to_digit(10).unwrap_or(0) as usize;
                j += 1;
            }
            if num > 0 && num <= params.len() {
                out.push_str(&format_param(&params[num - 1]));
            } else {
                out.extend(chars[i..j].iter());
            }
            i = j;
            continue;
        }
        if ch == '?' {
            if next_param < params.len() {
                out.push_str(&format_param(&params[next_param]));
                next_param += 1;
            } else {
                out.push(ch);
            }
            i += 1;
            continue;
        }
        if ch == '\'' && i + 1 < chars.len() {
            out.push(ch);
            i += 1;
            while i < chars.len() {
                out.push(chars[i]);
                if chars[i] == '\'' && (i + 1 >= chars.len() || chars[i + 1] != '\'') {
                    i += 1;
                    break;
                }
                if chars[i] == '\'' && i + 1 < chars.len() && chars[i + 1] == '\'' {
                    i += 1;
                }
                i += 1;
            }
            continue;
        }
        if ch == '-' && i + 1 < chars.len() && chars[i + 1] == '-' {
            while i < chars.len() && chars[i] != '\n' {
                out.push(chars[i]);
                i += 1;
            }
            continue;
        }
        if ch == '/' && i + 1 < chars.len() && chars[i + 1] == '*' {
            out.push(ch);
            out.push(chars[i + 1]);
            i += 2;
            while i + 1 < chars.len() && !(chars[i] == '*' && chars[i + 1] == '/') {
                out.push(chars[i]);
                i += 1;
            }
            if i + 1 < chars.len() {
                out.push(chars[i]);
                out.push(chars[i + 1]);
                i += 2;
            }
            continue;
        }
        out.push(ch);
        i += 1;
    }
    out
}

fn format_param(value: &Param) -> String {
    match value {
        Param::Null => "NULL".to_string(),
        Param::Bool(v) => {
            if *v {
                "TRUE".to_string()
            } else {
                "FALSE".to_string()
            }
        }
        Param::Int(v) => v.to_string(),
        Param::Float(v) => v.to_string(),
        Param::Decimal(v) => v.to_string(),
        Param::String(v) => format!("'{}'", escape(v)),
        Param::Bytes(v) => format!("X'{}'", hex::encode_upper(v)),
        Param::Date(v) => format!("DATE '{}'", v.format("%Y-%m-%d")),
        Param::Time(v) => format!("TIME '{}'", v.format("%H:%M:%S%.6f")),
        Param::Timestamp(v) => format!("TIMESTAMP '{}'", v.format("%Y-%m-%d %H:%M:%S%.6f")),
        Param::Json(v) => format!("JSON '{}'", escape(&v.to_string())),
        Param::Array(values) => format!("ARRAY[{}]", values.iter().map(format_param).collect::<Vec<_>>().join(", ")),
        Param::Inet(v) => format!("INET '{}'", escape(v)),
        Param::Cidr(v) => format!("CIDR '{}'", escape(v)),
        Param::Uuid(v) => format!("UUID '{}'", escape(v)),
    }
}

fn escape(value: &str) -> String {
    value.replace('\\', "\\\\").replace('\'', "''")
}
