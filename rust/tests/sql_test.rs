use scratchbird::{Param, Params};
use scratchbird::sql::substitute;

#[test]
fn substitute_positional() {
    let sql = "SELECT * FROM t WHERE id = ? AND name = ?";
    let out = substitute(
        sql,
        Params::Positional(vec![Param::from(42_i64), Param::from("Ada")]),
    );
    assert_eq!(out, "SELECT * FROM t WHERE id = 42 AND name = 'Ada'");
}

#[test]
fn substitute_named() {
    let sql = "SELECT * FROM users WHERE name = @name AND active = :active";
    let mut params = std::collections::HashMap::new();
    params.insert("name".to_string(), Param::from("Ada"));
    params.insert("active".to_string(), Param::from(true));
    let out = substitute(sql, Params::Named(params));
    assert_eq!(out, "SELECT * FROM users WHERE name = 'Ada' AND active = TRUE");
}

#[test]
fn substitute_binary() {
    let sql = "SELECT ?";
    let out = substitute(sql, Params::Positional(vec![Param::from(vec![1u8, 2u8])]));
    assert_eq!(out, "SELECT X'0102'");
}
