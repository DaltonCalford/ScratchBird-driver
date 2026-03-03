// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
use scratchbird::{normalize, Param, Params};

#[test]
fn normalize_positional() {
    let sql = "SELECT * FROM t WHERE id = ? AND name = ?";
    let normalized = normalize(
        sql,
        Params::Positional(vec![Param::from(42_i64), Param::from("Ada")]),
    )
    .unwrap();
    assert_eq!(normalized.sql, "SELECT * FROM t WHERE id = $1 AND name = $2");
    assert_eq!(normalized.params.len(), 2);
}

#[test]
fn normalize_named() {
    let sql = "SELECT * FROM users WHERE name = @name AND active = :active";
    let mut params = std::collections::HashMap::new();
    params.insert("name".to_string(), Param::from("Ada"));
    params.insert("active".to_string(), Param::from(true));
    let normalized = normalize(sql, Params::Named(params)).unwrap();
    assert_eq!(normalized.sql, "SELECT * FROM users WHERE name = $1 AND active = $2");
    assert_eq!(normalized.params.len(), 2);
}

#[test]
fn normalize_positional_ignores_escaped_string_literals() {
    let sql = "SELECT 'it''s ?' AS txt, ?::INTEGER";
    let normalized = normalize(sql, Params::Positional(vec![Param::from(42_i64)])).unwrap();
    assert_eq!(normalized.sql, "SELECT 'it''s ?' AS txt, $1::INTEGER");
    assert_eq!(normalized.params.len(), 1);
}

#[test]
fn normalize_named_ignores_escaped_string_literals() {
    let sql = "SELECT 'it''s @name' AS txt, @name";
    let mut params = std::collections::HashMap::new();
    params.insert("name".to_string(), Param::from("Ada"));
    let normalized = normalize(sql, Params::Named(params)).unwrap();
    assert_eq!(normalized.sql, "SELECT 'it''s @name' AS txt, $1");
    assert_eq!(normalized.params.len(), 1);
}

#[test]
fn normalize_named_errors_when_placeholders_exist_only_in_literals() {
    let sql = "SELECT 'it''s @name' AS txt";
    let mut params = std::collections::HashMap::new();
    params.insert("name".to_string(), Param::from("Ada"));
    let err = normalize(sql, Params::Named(params)).unwrap_err();
    assert_eq!(err.message, "named parameters provided but query has no placeholders");
}
