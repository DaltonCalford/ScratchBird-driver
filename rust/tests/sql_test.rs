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
