# Rust Driver API Reference

Status: Active (alpha lane)  
Priority: P1

## Client Construction

- `Client::new(config: Config) -> Client`
- `client.connect().await -> Result<()>`
- `client.close().await`

## Query and Execute

- `client.query(sql).await -> Result<QueryResult>`
- `client.query_params(sql, params).await -> Result<QueryResult>`
- `client.query_stream(sql).await -> Result<QueryStream>`
- `client.query_stream_params(sql, params).await -> Result<QueryStream>`
- `client.native_sql(sql, params) -> Result<String>`
- `client.native_callable_sql(sql, params) -> Result<String>`
- `client.call(sql, params).await -> Result<QueryResult>`
- `client.query_multi(sql, params).await -> Result<Vec<ResultSetSummary>>`
- `client.execute_multi(sql, params).await -> Result<Vec<ResultSetSummary>>`
- `client.execute_batch(sql, batch_params).await -> Result<BatchSummary>`
- `client.query_batch(sql, batch_params).await -> Result<BatchSummary>`
- `client.execute_with_generated_keys(sql, params).await -> Result<Vec<i64>>`

## Transaction and Savepoints

- `client.begin(options).await -> Result<()>`
- `client.commit(options).await -> Result<()>`
- `client.rollback(options).await -> Result<()>`
- `client.savepoint(name).await -> Result<()>`
- `client.release_savepoint(name).await -> Result<()>`
- `client.rollback_to_savepoint(name).await -> Result<()>`

## Metadata

- `client.query_metadata(collection).await -> Result<QueryResult>`
- `client.query_metadata_with_restrictions(collection, restrictions).await -> Result<QueryResult>`
- `Client::metadata_collection_name(collection) -> Result<&'static str>`

`query_metadata_with_restrictions(...)` applies alias-aware, collection-scoped metadata filtering and ignores restrictions that do not map to available metadata columns.
Supported metadata aliases include extended families such as `primary_keys`, `foreign_keys`, `type_info`, and unified `routines`.

## Key Result Types

- `QueryResult`: `columns`, `rows`, `row_count`, `command_tag`
- `FieldSummary`: `name`, `type_oid`, `format`, `nullable`
- `ResultSetSummary`: `rows`, `row_count`, `fields`, `command`, `last_insert_id`
- `BatchItemSummary`: `index`, `row_count`, `fields`, `command`, `last_insert_id`
- `BatchSummary`: `items`, `total_row_count`

## SQL Normalization Helpers

- `normalize(sql, params) -> Result<NormalizedQuery>`
- `normalize_callable(sql, params) -> Result<NormalizedQuery>`
- `normalize_callable_sql(sql) -> Result<String>`

## Error Model

- Driver methods return `Result<T, Error>`.
- `Error` includes `kind`, `message`, `sqlstate`, `detail`, `hint`.
