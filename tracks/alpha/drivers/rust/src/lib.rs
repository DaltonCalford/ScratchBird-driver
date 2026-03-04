// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
mod client;
mod config;
mod errors;
pub mod metadata;
pub mod pool;
pub mod protocol;
mod scram;
pub mod sql;
pub mod types;

// Resilience and monitoring modules
pub mod circuit_breaker;
pub mod keepalive;
pub mod leak_detection;
pub mod pipeline;
pub mod telemetry;

pub use client::{
    BatchItemSummary, BatchSummary, Client, CopyOptions, CopyResult, CopyState, FieldSummary,
    QueryResult, QueryStream, ResultSetSummary,
};
pub use config::Config;
pub use errors::{Error, ErrorKind, Result};
pub use pool::{with_retry, ConnectionPool, PoolConfig, PoolStats, PooledConnection, RetryConfig};
pub use sql::{normalize, normalize_callable, normalize_callable_sql, NormalizedQuery, Params};
pub use types::{
    Column, Date, Decimal, Geometry, Interval, Json, Jsonb, Money, Param, Range, RangeValue,
    RawValue, Time, Timestamp, TimestampTz, Value,
};

// Re-export key resilience types
pub use circuit_breaker::{
    with_circuit_breaker, CircuitBreaker, CircuitBreakerConfig, CircuitBreakerStats, CircuitState,
};
pub use keepalive::{KeepaliveConfig, KeepaliveTask, KeepaliveTracker};
pub use leak_detection::{
    CheckoutInfo, LeakDetectionConfig, LeakDetectionGuard, LeakDetector, LeakStatistics,
};
pub use pipeline::{PipelineBuilder, PipelineConfig, PipelineStats, QueryPipeline};
pub use telemetry::{
    export_prometheus_metrics, Metrics, SpanContext, TelemetryCollector, TelemetryConfig,
};
