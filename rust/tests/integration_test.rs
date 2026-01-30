// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
use std::env;
use std::time::Duration;

use scratchbird::{Client, Config};
use scratchbird::types::{Param, Value};
use scratchbird::sql::Params;
use tokio::time::timeout;

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

#[tokio::test]
async fn cancel_query() {
    let dsn = match env::var("SCRATCHBIRD_RUST_URL") {
        Ok(val) => val,
        Err(_) => return,
    };
    let cancel_sql = match env::var("SCRATCHBIRD_RUST_CANCEL_SQL") {
        Ok(val) => val,
        Err(_) => return,
    };
    let config = Config::from_dsn(&dsn).unwrap();
    let mut client = Client::new(config);
    client.connect().await.unwrap();
    let result = timeout(Duration::from_millis(200), client.query(&cancel_sql)).await;
    if result.is_ok() {
        client.close().await;
        panic!("expected cancel timeout");
    }
    let _ = client.cancel().await;
    client.close().await;
}
