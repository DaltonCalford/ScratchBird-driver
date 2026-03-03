// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
use std::collections::HashMap;

use crate::errors::{Error, ErrorKind, Result};
use crate::types::Param;

#[derive(Debug, Clone)]
pub enum Params {
    Positional(Vec<Param>),
    Named(HashMap<String, Param>),
}

#[derive(Debug, Clone)]
pub struct NormalizedQuery {
    pub sql: String,
    pub params: Vec<Param>,
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

pub fn normalize(sql: &str, params: Params) -> Result<NormalizedQuery> {
    match params {
        Params::Positional(values) => {
            if sql.contains('?') {
                let (rewritten, ordered) = rewrite_positional(sql, &values)?;
                Ok(NormalizedQuery { sql: rewritten, params: ordered })
            } else {
                Ok(NormalizedQuery { sql: sql.to_string(), params: values })
            }
        }
        Params::Named(values) => {
            if !has_named_params(sql) {
                return Err(Error::new(ErrorKind::Data, "named parameters provided but query has no placeholders"));
            }
            let (rewritten, ordered) = rewrite_named(sql, &values)?;
            Ok(NormalizedQuery { sql: rewritten, params: ordered })
        }
    }
}

fn has_named_params(sql: &str) -> bool {
    let mut in_string = false;
    let chars: Vec<char> = sql.chars().collect();
    let mut i = 0;
    while i + 1 < chars.len() {
        let ch = chars[i];
        if ch == '\'' {
            if in_string && i + 1 < chars.len() && chars[i + 1] == '\'' {
                i += 2;
                continue;
            }
            in_string = !in_string;
            i += 1;
            continue;
        }
        if !in_string && (ch == ':' || ch == '@') && is_ident_start(chars[i + 1]) {
            return true;
        }
        i += 1;
    }
    false
}

fn rewrite_named(sql: &str, params: &HashMap<String, Param>) -> Result<(String, Vec<Param>)> {
    let mut out = String::new();
    let mut ordered = Vec::new();
    let chars: Vec<char> = sql.chars().collect();
    let mut in_string = false;
    let mut i = 0;
    while i < chars.len() {
        let ch = chars[i];
        if ch == '\'' {
            out.push(ch);
            if in_string && i + 1 < chars.len() && chars[i + 1] == '\'' {
                out.push(chars[i + 1]);
                i += 2;
                continue;
            }
            in_string = !in_string;
            i += 1;
            continue;
        }
        if !in_string && (ch == ':' || ch == '@') && i + 1 < chars.len() && is_ident_start(chars[i + 1]) {
            let mut j = i + 1;
            while j < chars.len() && is_ident_part(chars[j]) {
                j += 1;
            }
            let key: String = chars[i + 1..j].iter().collect();
            let value = params
                .get(&key)
                .ok_or_else(|| Error::new(ErrorKind::Data, format!("missing named parameter: {}", key)))?;
            ordered.push(value.clone());
            out.push('$');
            out.push_str(&(ordered.len()).to_string());
            i = j;
            continue;
        }
        out.push(ch);
        i += 1;
    }
    Ok((out, ordered))
}

fn rewrite_positional(sql: &str, params: &[Param]) -> Result<(String, Vec<Param>)> {
    let mut out = String::new();
    let mut ordered = Vec::new();
    let chars: Vec<char> = sql.chars().collect();
    let mut in_string = false;
    let mut index = 0;
    let mut i = 0;
    while i < chars.len() {
        let ch = chars[i];
        if ch == '\'' {
            out.push(ch);
            if in_string && i + 1 < chars.len() && chars[i + 1] == '\'' {
                out.push(chars[i + 1]);
                i += 2;
                continue;
            }
            in_string = !in_string;
            i += 1;
            continue;
        }
        if !in_string && ch == '?' {
            if index >= params.len() {
                return Err(Error::new(ErrorKind::Data, "not enough parameters"));
            }
            ordered.push(params[index].clone());
            index += 1;
            out.push('$');
            out.push_str(&(ordered.len()).to_string());
            i += 1;
            continue;
        }
        out.push(ch);
        i += 1;
    }
    if index < params.len() {
        return Err(Error::new(ErrorKind::Data, "too many parameters"));
    }
    Ok((out, ordered))
}

fn is_ident_start(ch: char) -> bool {
    ch.is_ascii_alphabetic() || ch == '_'
}

fn is_ident_part(ch: char) -> bool {
    is_ident_start(ch) || ch.is_ascii_digit()
}
