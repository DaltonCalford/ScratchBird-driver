use std::env;

use scratchbird::{Client, Config};

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
