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

pub use client::{Client, QueryResult, QueryStream, CopyState, CopyOptions, CopyResult};
pub use config::Config;
pub use errors::{Error, ErrorKind, Result};
pub use pool::{ConnectionPool, PoolConfig, PoolStats, PooledConnection, RetryConfig, with_retry};
pub use sql::{normalize, NormalizedQuery, Params};
pub use types::{
    Column, Decimal, Geometry, Interval, Json, Jsonb, Money, Param, Range, RangeValue, RawValue, Time, Timestamp,
    TimestampTz, Date, Value,
};

// Re-export key resilience types
pub use circuit_breaker::{CircuitBreaker, CircuitBreakerConfig, CircuitState, CircuitBreakerStats, with_circuit_breaker};
pub use keepalive::{KeepaliveConfig, KeepaliveTracker, KeepaliveTask};
pub use leak_detection::{LeakDetector, LeakDetectionConfig, LeakDetectionGuard, LeakStatistics, CheckoutInfo};
pub use pipeline::{QueryPipeline, PipelineConfig, PipelineBuilder, PipelineStats};
pub use telemetry::{TelemetryCollector, TelemetryConfig, SpanContext, Metrics, export_prometheus_metrics};
