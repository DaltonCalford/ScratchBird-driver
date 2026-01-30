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
mod protocol;
mod scram;
pub mod sql;
pub mod types;

pub use client::{Client, QueryResult, QueryStream};
pub use config::Config;
pub use errors::{Error, ErrorKind, Result};
pub use sql::{normalize, NormalizedQuery, Params};
pub use types::{
    Column, Decimal, Geometry, Interval, Json, Jsonb, Money, Param, Range, RangeValue, RawValue, Time, Timestamp,
    TimestampTz, Date, Value,
};
