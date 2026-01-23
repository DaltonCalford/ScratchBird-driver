use std::env;

use scratchbird::{Client, Config};
use scratchbird::types::{Param, Value};
use scratchbird::sql::Params;

#[tokio::test]
async fn basic_query() {
    let dsn = match env::var("SCRATCHBIRD_RUST_URL") {
        Ok(val) => val,
        Err(_) => return,
    };
    let config = Config::from_dsn(&dsn).unwrap();
    let mut client = Client::new(config);
    client.connect().await.unwrap();
    let result = client.query("SELECT 1").await.unwrap();
    client.close().await;
    assert!(!result.rows.is_empty());
}

#[tokio::test]
async fn prepare_bind_query() {
    let dsn = match env::var("SCRATCHBIRD_RUST_URL") {
        Ok(val) => val,
        Err(_) => return,
    };
    let config = Config::from_dsn(&dsn).unwrap();
    let mut client = Client::new(config);
    client.connect().await.unwrap();
    let result = client
        .query_params("SELECT ?::INTEGER", Params::from(vec![Param::Int32(42)]))
        .await
        .unwrap();
    client.close().await;
    assert!(!result.rows.is_empty());
    match result.rows[0][0] {
        Value::Int32(v) => assert_eq!(v, 42),
        Value::Int64(v) => assert_eq!(v, 42),
        _ => panic!("unexpected value type"),
    }
}

#[tokio::test]
async fn types_fixture_query() {
    let dsn = match env::var("SCRATCHBIRD_RUST_URL") {
        Ok(val) => val,
        Err(_) => return,
    };
    let config = Config::from_dsn(&dsn).unwrap();
    let mut client = Client::new(config);
    client.connect().await.unwrap();
    let result = client.query("SELECT * FROM sb_conformance.type_coverage").await.unwrap();
    client.close().await;
    assert!(!result.rows.is_empty());
}
