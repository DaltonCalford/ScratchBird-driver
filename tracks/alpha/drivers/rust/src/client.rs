// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
use std::collections::HashMap;
use std::sync::Arc;
use std::time::Duration;

use rand::RngCore;
use tokio::io::{AsyncRead, AsyncReadExt, AsyncWrite, AsyncWriteExt};
use tokio::net::TcpStream;
use tokio::time::timeout;
use tokio_rustls::client::TlsStream;
use tokio_rustls::TlsConnector;

use crate::config::Config;
use crate::circuit_breaker::{CircuitBreaker, CircuitBreakerConfig};
use crate::errors::{error_from_sqlstate, Error, ErrorKind, Result};
use crate::keepalive::{KeepaliveConfig, KeepaliveTracker};
use crate::metadata::{normalize_metadata_collection_name, resolve_metadata_collection_query};
use crate::protocol;
use crate::protocol::MessageHeader;
use crate::scram::ScramExchange;
use crate::sql::{normalize, Params};
use crate::telemetry::{SpanContext, TelemetryCollector, TelemetryConfig};
use crate::types::{decode_value, encode_param, Column, Param, Value, FORMAT_BINARY};

const QUERY_FLAG_BINARY_RESULT: u32 = 0x04;
const MANAGER_PROTOCOL_MAGIC: u32 = 0x4244_4253; // SBDB
const MANAGER_PROTOCOL_VERSION: u16 = 0x0101;
const MANAGER_HEADER_SIZE: usize = 12;
const MANAGER_MAX_PAYLOAD_SIZE: u32 = 16 * 1024 * 1024;
const MCP_PROTOCOL_VERSION: u16 = 0x0100;

const MCP_MSG_CONNECT_RESPONSE: u8 = 0x02;
const MCP_MSG_AUTH_CHALLENGE: u8 = 0x12;
const MCP_MSG_AUTH_RESPONSE: u8 = 0x11;
const MCP_MSG_STATUS_RESPONSE: u8 = 0x64;
const MCP_MSG_HELLO: u8 = 0x65;
const MCP_MSG_AUTH_START: u8 = 0x66;
const MCP_MSG_AUTH_CONTINUE: u8 = 0x67;
const MCP_MSG_DB_CONNECT: u8 = 0x69;
const MCP_AUTH_METHOD_TOKEN: u8 = 4;

fn normalize_native_protocol(value: &str) -> Option<&'static str> {
    match value.trim().to_ascii_lowercase().as_str() {
        "" | "native" | "scratchbird" | "scratchbird-native" | "scratchbird_native" => Some("native"),
        _ => None,
    }
}

fn normalize_front_door_mode(value: &str) -> Option<&'static str> {
    match value.trim().to_ascii_lowercase().as_str() {
        "" | "direct" => Some("direct"),
        "manager_proxy" | "manager-proxy" | "managed" => Some("manager_proxy"),
        _ => None,
    }
}

fn append_u16(out: &mut Vec<u8>, value: u16) {
    out.extend_from_slice(&value.to_le_bytes());
}

fn append_u32(out: &mut Vec<u8>, value: u32) {
    out.extend_from_slice(&value.to_le_bytes());
}

fn append_lpreface(out: &mut Vec<u8>, value: &str) {
    append_u32(out, value.len() as u32);
    out.extend_from_slice(value.as_bytes());
}

pub struct Client {
    config: Config,
    stream: Option<Box<dyn AsyncReadWrite>>,
    connected: bool,
    attachment_id: [u8; 16],
    txn_id: u64,
    sequence: u32,
    last_query_sequence: u32,
    authed: bool,
    parameters: HashMap<String, String>,
    notification_handlers: Vec<Box<dyn Fn(&protocol::Notification) + Send + Sync>>,
    last_plan: Option<protocol::QueryPlan>,
    last_sblr: Option<protocol::SblrCompiled>,
    circuit_breaker: Arc<CircuitBreaker>,
    telemetry: Arc<TelemetryCollector>,
    keepalive_tracker: Arc<KeepaliveTracker>,
}

#[derive(Debug, Clone)]
pub struct QueryResult {
    pub columns: Vec<Column>,
    pub rows: Vec<Vec<Value>>,
    pub row_count: i64,
    pub command_tag: String,
}

pub struct QueryStream<'a> {
    client: &'a mut Client,
    columns: Vec<protocol::ColumnInfo>,
    row_count: i64,
    command_tag: String,
    done: bool,
    page_size: u32,
    telemetry: Arc<TelemetryCollector>,
    circuit_breaker: Arc<CircuitBreaker>,
    span: Option<SpanContext>,
    finalized: bool,
}

/// Represents the state of a copy operation
#[derive(Debug, Clone)]
pub enum CopyState {
    /// Waiting for the server to respond
    Waiting,
    /// Copy data can be sent to the server (COPY FROM)
    Sending { format: u8, window_bytes: u32 },
    /// Copy data is being received from the server (COPY TO)
    Receiving { format: u8, column_formats: Vec<u32> },
    /// Bidirectional copy is active
    Both { format: u8, window_bytes: u32 },
    /// Copy operation completed successfully
    Complete,
    /// Copy operation failed
    Failed { error: String },
}

/// Options for copy operations
#[derive(Debug, Clone)]
pub struct CopyOptions {
    /// Format of the copy data (text or binary)
    pub format: u8,
    /// Maximum number of bytes to buffer before sending
    pub buffer_size: usize,
}

impl Default for CopyOptions {
    fn default() -> Self {
        Self {
            format: protocol::COPY_FORMAT_TEXT,
            buffer_size: 65536,
        }
    }
}

/// Result of a copy operation
#[derive(Debug, Clone)]
pub struct CopyResult {
    /// Number of rows affected
    pub rows_affected: u64,
    /// Command tag from the server
    pub command_tag: String,
}

#[derive(Debug, Clone, Default)]
pub struct TxnBeginOptions {
    pub isolation_level: Option<u8>,
    pub access_mode: Option<u8>,
    pub deferrable: Option<bool>,
    pub wait: Option<bool>,
    pub timeout_ms: Option<u32>,
    pub autocommit_mode: Option<u8>,
    pub conflict_action: u8,
}

#[derive(Debug, Clone, Default)]
pub struct TxnEndOptions {
    pub flags: u8,
}

trait AsyncReadWrite: AsyncRead + AsyncWrite + Unpin + Send {}
impl<T> AsyncReadWrite for T where T: AsyncRead + AsyncWrite + Unpin + Send {}

impl Client {
    pub fn new(config: Config) -> Self {
        Self {
            config,
            stream: None,
            connected: false,
            attachment_id: [0u8; 16],
            txn_id: 0,
            sequence: 0,
            last_query_sequence: 0,
            authed: false,
            parameters: HashMap::new(),
            notification_handlers: Vec::new(),
            last_plan: None,
            last_sblr: None,
            circuit_breaker: Arc::new(CircuitBreaker::new(CircuitBreakerConfig::default())),
            telemetry: Arc::new(TelemetryCollector::new(TelemetryConfig::default())),
            keepalive_tracker: Arc::new(KeepaliveTracker::new(KeepaliveConfig::default())),
        }
    }

    pub async fn connect(&mut self) -> Result<()> {
        let startup_params = self.preflight_connect()?;
        let manager_proxy = self.config.front_door_mode == "manager_proxy";
        let stream = self.connect_transport().await?;
        self.stream = Some(stream);
        if manager_proxy {
            self.perform_manager_connect().await?;
        }
        self.handshake(startup_params).await?;
        self.apply_schema().await?;
        self.connected = true;
        Ok(())
    }

    fn preflight_connect(&mut self) -> Result<HashMap<String, String>> {
        let protocol = normalize_native_protocol(&self.config.protocol).ok_or_else(|| {
            Error::with_sqlstate(
                ErrorKind::NotSupported,
                "only protocol=native is supported; connect to the native parser listener/port",
                Some("0A000".to_string()),
                None,
                None,
            )
        })?;
        self.config.protocol = protocol.to_string();

        let front_door_mode = normalize_front_door_mode(&self.config.front_door_mode).ok_or_else(|| {
            Error::with_sqlstate(
                ErrorKind::NotSupported,
                "front_door_mode must be direct or manager_proxy",
                Some("0A000".to_string()),
                None,
                None,
            )
        })?;
        self.config.front_door_mode = front_door_mode.to_string();

        if self.config.user.is_empty() || self.config.database.is_empty() {
            return Err(Error::new(ErrorKind::Connection, "user and database are required"));
        }
        if !self.config.binary_transfer {
            return Err(Error::with_sqlstate(
                ErrorKind::NotSupported,
                "binary_transfer=false is not supported",
                Some("0A000".to_string()),
                None,
                None,
            ));
        }
        if self.config.compression.eq_ignore_ascii_case("zstd") {
            return Err(Error::with_sqlstate(
                ErrorKind::NotSupported,
                "compression=zstd is not supported",
                Some("0A000".to_string()),
                None,
                None,
            ));
        }
        if self.config.front_door_mode == "manager_proxy" && self.config.manager_auth_token.is_empty() {
            return Err(Error::new(
                ErrorKind::Connection,
                "manager_proxy mode requires manager_auth_token",
            ));
        }
        self.build_startup_params()
    }

    fn build_startup_params(&self) -> Result<HashMap<String, String>> {
        let mut params = HashMap::new();
        params.insert("database".to_string(), self.config.database.clone());
        params.insert("user".to_string(), self.config.user.clone());
        if !self.config.role.is_empty() {
            params.insert("role".to_string(), self.config.role.clone());
        }
        if !self.config.application_name.is_empty() {
            params.insert("application_name".to_string(), self.config.application_name.clone());
        }
        let auth_plugin_selection = protocol::AuthPluginSelection {
            method_id: self
                .config
                .extra
                .get(protocol::AUTH_PARAM_METHOD_ID)
                .cloned()
                .unwrap_or_default(),
            payload_json: self
                .config
                .extra
                .get(protocol::AUTH_PARAM_PAYLOAD_JSON)
                .cloned()
                .unwrap_or_default(),
            payload_b64: self
                .config
                .extra
                .get(protocol::AUTH_PARAM_PAYLOAD_B64)
                .cloned()
                .unwrap_or_default(),
            provider_profile: self
                .config
                .extra
                .get(protocol::AUTH_PARAM_PROVIDER_PROFILE)
                .cloned()
                .unwrap_or_default(),
        };
        protocol::apply_auth_plugin_selection(&mut params, &auth_plugin_selection)?;
        Ok(params)
    }

    pub async fn close(&mut self) {
        if let Some(mut stream) = self.stream.take() {
            let _ = stream.shutdown().await;
        }
        self.connected = false;
        self.authed = false;
        self.txn_id = 0;
        self.sequence = 0;
    }

    pub async fn query(&mut self, sql: &str) -> Result<QueryResult> {
        self.query_params(sql, Params::Positional(Vec::new())).await
    }

    pub fn native_sql(&self, sql: &str, params: Params) -> Result<String> {
        let normalized = normalize(sql, params)?;
        Ok(normalized.sql)
    }

    pub async fn query_params(&mut self, sql: &str, params: Params) -> Result<QueryResult> {
        self.ensure_connected()?;
        let span = self.begin_operation("query").await?;
        let normalized = normalize(sql, params)?;
        if normalized.params.is_empty() {
            self.send_simple_query(&normalized.sql, 0, 0).await?;
        } else {
            self.send_extended_query(&normalized.sql, &normalized.params, 0).await?;
        }
        let result = self.collect_results().await;
        self.end_operation(span, result.is_ok()).await;
        result
    }

    pub async fn query_stream(&mut self, sql: &str) -> Result<QueryStream<'_>> {
        self.ensure_connected()?;
        let span = self.begin_operation("query_stream").await?;
        let telemetry = Arc::clone(&self.telemetry);
        let circuit_breaker = Arc::clone(&self.circuit_breaker);
        let page_size = self.config.fetch_size.max(1);
        self.send_simple_query(sql, page_size, 0).await?;
        Ok(QueryStream {
            client: self,
            columns: Vec::new(),
            row_count: -1,
            command_tag: String::new(),
            done: false,
            page_size,
            telemetry,
            circuit_breaker,
            span,
            finalized: false,
        })
    }

    pub async fn query_stream_params(&mut self, sql: &str, params: Params) -> Result<QueryStream<'_>> {
        self.ensure_connected()?;
        let span = self.begin_operation("query_stream").await?;
        let telemetry = Arc::clone(&self.telemetry);
        let circuit_breaker = Arc::clone(&self.circuit_breaker);
        let normalized = normalize(sql, params)?;
        let page_size = self.config.fetch_size.max(1);
        if normalized.params.is_empty() {
            self.send_simple_query(&normalized.sql, page_size, 0).await?;
        } else {
            self.send_extended_query(&normalized.sql, &normalized.params, page_size).await?;
        }
        Ok(QueryStream {
            client: self,
            columns: Vec::new(),
            row_count: -1,
            command_tag: String::new(),
            done: false,
            page_size,
            telemetry,
            circuit_breaker,
            span,
            finalized: false,
        })
    }

    pub async fn query_metadata(&mut self, collection: &str) -> Result<QueryResult> {
        let Some(query) = resolve_metadata_collection_query(collection) else {
            return Err(Error::with_sqlstate(
                ErrorKind::NotSupported,
                format!("metadata collection '{}' is not supported", collection),
                Some("0A000".to_string()),
                None,
                None,
            ));
        };
        self.query(query).await
    }

    pub fn metadata_collection_name(collection: &str) -> Result<&'static str> {
        normalize_metadata_collection_name(collection).ok_or_else(|| {
            Error::with_sqlstate(
                ErrorKind::NotSupported,
                format!("metadata collection '{}' is not supported", collection),
                Some("0A000".to_string()),
                None,
                None,
            )
        })
    }

    pub async fn begin(&mut self, options: Option<TxnBeginOptions>) -> Result<()> {
        self.begin_transaction(options).await
    }

    pub async fn commit(&mut self, options: Option<TxnEndOptions>) -> Result<()> {
        self.commit_transaction(options).await
    }

    pub async fn rollback(&mut self, options: Option<TxnEndOptions>) -> Result<()> {
        self.rollback_transaction(options).await
    }

    pub async fn begin_transaction(&mut self, options: Option<TxnBeginOptions>) -> Result<()> {
        self.ensure_connected()?;
        self.ensure_no_active_transaction()?;
        let opts = options.unwrap_or_default();
        let mut flags = 0u16;
        let isolation = opts.isolation_level.unwrap_or(protocol::ISOLATION_READ_COMMITTED);
        if opts.isolation_level.is_some() {
            flags |= protocol::TXN_FLAG_HAS_ISOLATION;
        }
        if opts.access_mode.is_some() {
            flags |= protocol::TXN_FLAG_HAS_ACCESS;
        }
        if opts.deferrable.is_some() {
            flags |= protocol::TXN_FLAG_HAS_DEFERRABLE;
        }
        if opts.wait.is_some() {
            flags |= protocol::TXN_FLAG_HAS_WAIT;
        }
        if opts.timeout_ms.is_some() {
            flags |= protocol::TXN_FLAG_HAS_TIMEOUT;
        }
        if opts.autocommit_mode.is_some() {
            flags |= protocol::TXN_FLAG_HAS_AUTOCOMMIT;
        }
        let payload = protocol::build_txn_begin_payload(
            flags,
            opts.conflict_action,
            opts.autocommit_mode.unwrap_or(0),
            isolation,
            opts.access_mode.unwrap_or(0),
            if opts.deferrable.unwrap_or(false) { 1 } else { 0 },
            if opts.wait.unwrap_or(false) { 1 } else { 0 },
            opts.timeout_ms.unwrap_or(0),
        );
        self.send_message(protocol::MSG_TXN_BEGIN, &payload, 0, false).await?;
        self.drain_until_ready().await
    }

    pub async fn commit_transaction(&mut self, options: Option<TxnEndOptions>) -> Result<()> {
        self.ensure_connected()?;
        self.ensure_transaction_active("commit")?;
        let flags = options.map(|opt| opt.flags).unwrap_or(0);
        let payload = protocol::build_txn_commit_payload(flags);
        self.send_message(protocol::MSG_TXN_COMMIT, &payload, 0, false).await?;
        self.drain_until_ready().await
    }

    pub async fn rollback_transaction(&mut self, options: Option<TxnEndOptions>) -> Result<()> {
        self.ensure_connected()?;
        self.ensure_transaction_active("rollback")?;
        let flags = options.map(|opt| opt.flags).unwrap_or(0);
        let payload = protocol::build_txn_rollback_payload(flags);
        self.send_message(protocol::MSG_TXN_ROLLBACK, &payload, 0, false).await?;
        self.drain_until_ready().await
    }

    pub async fn savepoint(&mut self, name: &str) -> Result<()> {
        self.ensure_connected()?;
        self.ensure_transaction_active("savepoint")?;
        let name = Self::validate_savepoint_name(name)?;
        let payload = protocol::build_txn_savepoint_payload(name);
        self.send_message(protocol::MSG_TXN_SAVEPOINT, &payload, 0, false).await?;
        self.drain_until_ready().await
    }

    pub async fn release_savepoint(&mut self, name: &str) -> Result<()> {
        self.ensure_connected()?;
        self.ensure_transaction_active("release savepoint")?;
        let name = Self::validate_savepoint_name(name)?;
        let payload = protocol::build_txn_release_payload(name);
        self.send_message(protocol::MSG_TXN_RELEASE, &payload, 0, false).await?;
        self.drain_until_ready().await
    }

    pub async fn rollback_to_savepoint(&mut self, name: &str) -> Result<()> {
        self.ensure_connected()?;
        self.ensure_transaction_active("rollback to savepoint")?;
        let name = Self::validate_savepoint_name(name)?;
        let payload = protocol::build_txn_rollback_to_payload(name);
        self.send_message(protocol::MSG_TXN_ROLLBACK_TO, &payload, 0, false).await?;
        self.drain_until_ready().await
    }

    pub async fn set_option(&mut self, name: &str, value: &str) -> Result<()> {
        self.ensure_connected()?;
        let payload = protocol::build_set_option_payload(name, value);
        self.send_message(protocol::MSG_SET_OPTION, &payload, 0, false).await?;
        self.drain_until_ready().await
    }

    pub async fn ping(&mut self) -> Result<()> {
        self.ensure_connected()?;
        self.send_message(protocol::MSG_PING, &[], 0, false).await?;
        loop {
            let msg = self.recv_message().await?;
            if self.handle_async_message(&msg)? {
                continue;
            }
            if msg.header.msg_type == protocol::MSG_PONG || msg.header.msg_type == protocol::MSG_READY {
                if msg.header.msg_type == protocol::MSG_READY {
                    let (_status, txn_id, _visibility) = protocol::parse_ready(&msg.payload)?;
                    self.apply_txn_state(txn_id);
                }
                return Ok(());
            }
            if msg.header.msg_type == protocol::MSG_ERROR {
                return self.raise_protocol_error(&msg.payload);
            }
        }
    }

    pub async fn terminate(&mut self) -> Result<()> {
        if !self.connected {
            self.close().await;
            return Ok(());
        }
        self.send_message(protocol::MSG_TERMINATE, &[], 0, false).await?;
        self.close().await;
        Ok(())
    }

    pub async fn subscribe(&mut self, subscribe_type: u8, channel: &str, filter_expr: &str) -> Result<()> {
        self.ensure_connected()?;
        let payload = protocol::build_subscribe_payload(subscribe_type, channel, filter_expr);
        self.send_message(protocol::MSG_SUBSCRIBE, &payload, 0, false).await?;
        self.drain_until_ready().await
    }

    pub async fn unsubscribe(&mut self, channel: &str) -> Result<()> {
        self.ensure_connected()?;
        let payload = protocol::build_unsubscribe_payload(channel);
        self.send_message(protocol::MSG_UNSUBSCRIBE, &payload, 0, false).await?;
        self.drain_until_ready().await
    }

    pub async fn execute_sblr(&mut self, sblr_hash: u64, sblr_bytecode: &[u8], params: &[Param]) -> Result<QueryResult> {
        self.ensure_connected()?;
        let span = self.begin_operation("sblr_execute").await?;
        let mut encoded = Vec::with_capacity(params.len());
        for param in params {
            let (value, _oid) = encode_param(param)?;
            encoded.push(value);
        }
        let payload = protocol::build_sblr_execute_payload(sblr_hash, sblr_bytecode, &encoded);
        self.last_plan = None;
        self.last_sblr = None;
        let sequence = self.send_message(protocol::MSG_SBLR_EXECUTE, &payload, 0, false).await?;
        self.last_query_sequence = sequence;
        self.send_message(protocol::MSG_SYNC, &[], 0, false).await?;
        let result = self.collect_results().await;
        self.end_operation(span, result.is_ok()).await;
        result
    }

    pub async fn stream_control(&mut self, control_type: u8, window_size: u32, timeout_ms: u32) -> Result<()> {
        self.ensure_connected()?;
        let payload = protocol::build_stream_control_payload(control_type, window_size, timeout_ms);
        self.send_message(protocol::MSG_STREAM_CONTROL, &payload, 0, false).await?;
        Ok(())
    }

    pub async fn attach_create(&mut self, emulation_mode: &str, db_name: &str) -> Result<()> {
        self.ensure_connected()?;
        let payload = protocol::build_attach_create_payload(emulation_mode, db_name);
        self.send_message(protocol::MSG_ATTACH_CREATE, &payload, 0, false).await?;
        self.drain_until_ready().await
    }

    pub async fn attach_detach(&mut self) -> Result<()> {
        self.ensure_connected()?;
        self.send_message(protocol::MSG_ATTACH_DETACH, &[], 0, false).await?;
        self.drain_until_ready().await
    }

    pub async fn attach_list(&mut self) -> Result<QueryResult> {
        self.ensure_connected()?;
        self.send_message(protocol::MSG_ATTACH_LIST, &[], 0, false).await?;
        self.send_message(protocol::MSG_SYNC, &[], 0, false).await?;
        self.collect_results().await
    }

    pub fn on_notification<F>(&mut self, handler: F)
    where
        F: Fn(&protocol::Notification) + Send + Sync + 'static,
    {
        self.notification_handlers.push(Box::new(handler));
    }

    pub fn last_query_plan(&self) -> Option<&protocol::QueryPlan> {
        self.last_plan.as_ref()
    }

    pub fn last_sblr_compiled(&self) -> Option<&protocol::SblrCompiled> {
        self.last_sblr.as_ref()
    }

    // ============================================================================
    // COPY Operations (SBWP 1.1)
    // ============================================================================

    /// Execute a COPY FROM operation (client sends data to server).
    /// 
    /// # Arguments
    /// * `sql` - The COPY SQL statement (e.g., "COPY table FROM STDIN")
    /// * `data` - The data to be copied
    /// * `options` - Optional copy options
    /// 
    /// # Example
    /// ```ignore
    /// let data = b"1,hello\n2,world\n".to_vec();
    /// let result = client.copy_in("COPY my_table FROM STDIN (FORMAT csv)", data, None).await?;
    /// ```
    pub async fn copy_in(&mut self, sql: &str, data: Vec<u8>, options: Option<CopyOptions>) -> Result<CopyResult> {
        self.ensure_connected()?;
        let span = self.begin_operation("copy_in").await?;
        let opts = options.unwrap_or_default();
        
        // Request binary copy feature if using binary format
        if opts.format == protocol::COPY_FORMAT_BINARY {
            self.request_binary_copy_feature().await?;
        }
        
        // Send the COPY query
        self.send_simple_query(sql, 0, 0).await?;
        
        // Wait for CopyInResponse
        let copy_response = self.wait_for_copy_in_response().await?;
        
        let result = match copy_response {
            CopyState::Sending { format: _, window_bytes: _ } => {
                // Send the copy data in chunks
                self.send_copy_data_in_chunks(&data, opts.buffer_size).await?;
                
                // Send CopyDone
                self.send_copy_done().await?;
                
                // Wait for CommandComplete
                self.wait_for_copy_complete().await
            }
            CopyState::Failed { error } => {
                Err(Error::new(ErrorKind::Data, format!("copy failed: {}", error)))
            }
            _ => Err(Error::new(ErrorKind::Connection, "unexpected copy response")),
        };
        self.end_operation(span, result.is_ok()).await;
        result
    }

    /// Execute a COPY TO operation (server sends data to client).
    /// 
    /// # Arguments
    /// * `sql` - The COPY SQL statement (e.g., "COPY table TO STDOUT")
    /// * `options` - Optional copy options
    /// 
    /// # Returns
    /// The data received from the server
    pub async fn copy_out(&mut self, sql: &str, options: Option<CopyOptions>) -> Result<Vec<u8>> {
        self.ensure_connected()?;
        let span = self.begin_operation("copy_out").await?;
        let opts = options.unwrap_or_default();
        
        // Request binary copy feature if using binary format
        if opts.format == protocol::COPY_FORMAT_BINARY {
            self.request_binary_copy_feature().await?;
        }
        
        // Send the COPY query
        self.send_simple_query(sql, 0, 0).await?;
        
        // Wait for CopyOutResponse and collect data
        let result = self.collect_copy_out_data().await;
        self.end_operation(span, result.is_ok()).await;
        result
    }

    /// Send copy data in chunks to avoid memory issues with large datasets.
    /// 
    /// # Arguments
    /// * `sql` - The COPY SQL statement
    /// * `data_stream` - Async stream of data chunks
    pub async fn copy_in_streaming<F, Fut>(&mut self, sql: &str, mut data_stream: F) -> Result<CopyResult>
    where
        F: FnMut() -> Fut,
        Fut: std::future::Future<Output = Result<Option<Vec<u8>>>>,
    {
        self.ensure_connected()?;
        let span = self.begin_operation("copy_in_stream").await?;
        
        // Send the COPY query
        self.send_simple_query(sql, 0, 0).await?;
        
        // Wait for CopyInResponse
        let copy_response = self.wait_for_copy_in_response().await?;
        
        let result = match copy_response {
            CopyState::Sending { .. } => {
                // Stream the data
                loop {
                    match data_stream().await? {
                        Some(chunk) => {
                            let payload = protocol::build_copy_data_payload(&chunk);
                            self.send_message(protocol::MSG_COPY_DATA, &payload, 0, false).await?;
                        }
                        None => break,
                    }
                }
                
                // Send CopyDone
                self.send_copy_done().await?;
                
                // Wait for CommandComplete
                self.wait_for_copy_complete().await
            }
            CopyState::Failed { error } => {
                Err(Error::new(ErrorKind::Data, format!("copy failed: {}", error)))
            }
            _ => Err(Error::new(ErrorKind::Connection, "unexpected copy response")),
        };
        self.end_operation(span, result.is_ok()).await;
        result
    }

    /// Send a chunk of copy data.
    /// This is a low-level method for advanced use cases.
    pub async fn send_copy_data(&mut self, data: &[u8]) -> Result<()> {
        let payload = protocol::build_copy_data_payload(data);
        self.send_message(protocol::MSG_COPY_DATA, &payload, 0, false).await?;
        Ok(())
    }

    /// Signal that all copy data has been sent.
    /// This is a low-level method for advanced use cases.
    pub async fn send_copy_done(&mut self) -> Result<()> {
        let payload = protocol::build_copy_done_payload();
        self.send_message(protocol::MSG_COPY_DONE, &payload, 0, false).await?;
        Ok(())
    }

    /// Signal a copy failure with an error message.
    /// This is a low-level method for advanced use cases.
    pub async fn send_copy_fail(&mut self, error_message: &str) -> Result<()> {
        let payload = protocol::build_copy_fail_payload(error_message);
        self.send_message(protocol::MSG_COPY_FAIL, &payload, 0, false).await?;
        Ok(())
    }

    // ============================================================================
    // Private COPY helper methods
    // ============================================================================

    async fn request_binary_copy_feature(&mut self) -> Result<()> {
        // The binary copy feature is negotiated during handshake
        // This method can be used to verify the feature is available
        Ok(())
    }

    async fn wait_for_copy_in_response(&mut self) -> Result<CopyState> {
        loop {
            let msg = self.recv_message().await?;
            if self.handle_async_message(&msg)? {
                continue;
            }
            match msg.header.msg_type {
                protocol::MSG_COPY_IN_RESPONSE => {
                    let response = protocol::parse_copy_in_response(&msg.payload)?;
                    return Ok(CopyState::Sending {
                        format: response.format,
                        window_bytes: response.window_bytes,
                    });
                }
                protocol::MSG_ERROR => {
                    let (_, _, message, _, _) = protocol::parse_error_message(&msg.payload)?;
                    return Ok(CopyState::Failed { error: message });
                }
                protocol::MSG_READY => {
                    let (_status, txn_id, _visibility) = protocol::parse_ready(&msg.payload)?;
                    self.apply_txn_state(txn_id);
                    return Ok(CopyState::Complete);
                }
                _ => continue,
            }
        }
    }

    async fn send_copy_data_in_chunks(&mut self, data: &[u8], chunk_size: usize) -> Result<()> {
        for chunk in data.chunks(chunk_size) {
            let payload = protocol::build_copy_data_payload(chunk);
            self.send_message(protocol::MSG_COPY_DATA, &payload, 0, false).await?;
        }
        Ok(())
    }

    async fn wait_for_copy_complete(&mut self) -> Result<CopyResult> {
        loop {
            let msg = self.recv_message().await?;
            if self.handle_async_message(&msg)? {
                continue;
            }
            match msg.header.msg_type {
                protocol::MSG_COMMAND_COMPLETE => {
                    let (_cmd_type, rows_affected, _last_id, tag) = protocol::parse_command_complete(&msg.payload)?;
                    return Ok(CopyResult {
                        rows_affected,
                        command_tag: tag,
                    });
                }
                protocol::MSG_ERROR => return self.raise_protocol_error(&msg.payload),
                protocol::MSG_READY => {
                    let (_status, txn_id, _visibility) = protocol::parse_ready(&msg.payload)?;
                    self.apply_txn_state(txn_id);
                    return Ok(CopyResult {
                        rows_affected: 0,
                        command_tag: "COPY".to_string(),
                    });
                }
                _ => continue,
            }
        }
    }

    async fn collect_copy_out_data(&mut self) -> Result<Vec<u8>> {
        let mut result = Vec::new();
        
        loop {
            let msg = self.recv_message().await?;
            if self.handle_async_message(&msg)? {
                continue;
            }
            match msg.header.msg_type {
                protocol::MSG_COPY_OUT_RESPONSE => {
                    let _response = protocol::parse_copy_out_response(&msg.payload)?;
                    // The response tells us the format, we just collect data
                    continue;
                }
                protocol::MSG_COPY_DATA => {
                    let data = protocol::parse_copy_data(&msg.payload)?;
                    result.extend_from_slice(&data.data);
                }
                protocol::MSG_COPY_DONE => {
                    // Copy operation complete, wait for CommandComplete
                    continue;
                }
                protocol::MSG_COMMAND_COMPLETE => {
                    // Copy operation fully complete
                    continue;
                }
                protocol::MSG_READY => {
                    let (_status, txn_id, _visibility) = protocol::parse_ready(&msg.payload)?;
                    self.apply_txn_state(txn_id);
                    return Ok(result);
                }
                protocol::MSG_ERROR => return self.raise_protocol_error(&msg.payload),
                _ => continue,
            }
        }
    }

    pub async fn cancel(&mut self) -> Result<()> {
        let payload = protocol::build_cancel_payload(0, self.last_query_sequence);
        self.send_message(protocol::MSG_CANCEL, &payload, protocol::MSG_FLAG_URGENT, false)
            .await
            .map(|_| ())
    }

    async fn send_manager_frame(&mut self, msg_type: u8, payload: &[u8]) -> Result<()> {
        let stream = self.stream.as_mut().ok_or_else(|| Error::new(ErrorKind::Connection, "no active socket"))?;
        let mut frame = Vec::with_capacity(MANAGER_HEADER_SIZE + payload.len());
        append_u32(&mut frame, MANAGER_PROTOCOL_MAGIC);
        append_u16(&mut frame, MANAGER_PROTOCOL_VERSION);
        frame.push(msg_type);
        frame.push(0);
        append_u32(&mut frame, payload.len() as u32);
        frame.extend_from_slice(payload);
        if self.config.socket_timeout_ms > 0 {
            timeout(Duration::from_millis(self.config.socket_timeout_ms), stream.write_all(&frame))
                .await
                .map_err(|_| Error::new(ErrorKind::Connection, "socket write timeout"))??;
        } else {
            stream.write_all(&frame).await?;
        }
        Ok(())
    }

    async fn recv_manager_frame(&mut self) -> Result<(u8, Vec<u8>)> {
        let mut header = [0u8; MANAGER_HEADER_SIZE];
        self.read_exact(&mut header).await?;
        let magic = u32::from_le_bytes([header[0], header[1], header[2], header[3]]);
        if magic != MANAGER_PROTOCOL_MAGIC {
            return Err(Error::new(ErrorKind::Connection, "manager frame magic mismatch"));
        }
        let version = u16::from_le_bytes([header[4], header[5]]);
        if version != MANAGER_PROTOCOL_VERSION {
            return Err(Error::new(ErrorKind::Connection, "manager frame version mismatch"));
        }
        let msg_type = header[6];
        let payload_len = u32::from_le_bytes([header[8], header[9], header[10], header[11]]);
        if payload_len > MANAGER_MAX_PAYLOAD_SIZE {
            return Err(Error::new(ErrorKind::Connection, "manager payload too large"));
        }
        let mut payload = vec![0u8; payload_len as usize];
        if payload_len > 0 {
            self.read_exact(&mut payload).await?;
        }
        Ok((msg_type, payload))
    }

    async fn perform_manager_connect(&mut self) -> Result<()> {
        if self.config.manager_auth_token.is_empty() {
            return Err(Error::new(
                ErrorKind::Connection,
                "manager_proxy mode requires manager_auth_token",
            ));
        }
        let manager_user = if !self.config.manager_username.is_empty() {
            self.config.manager_username.clone()
        } else if !self.config.user.is_empty() {
            self.config.user.clone()
        } else {
            "admin".to_string()
        };
        let manager_database = if !self.config.manager_database.is_empty() {
            self.config.manager_database.clone()
        } else {
            self.config.database.clone()
        };
        let manager_profile = if !self.config.manager_connection_profile.is_empty() {
            self.config.manager_connection_profile.clone()
        } else {
            "native_v3".to_string()
        };
        let manager_intent = if !self.config.manager_client_intent.is_empty() {
            self.config.manager_client_intent.clone()
        } else {
            "native_v3".to_string()
        };

        let hello = {
            let mut out = Vec::with_capacity(4);
            append_u16(&mut out, MCP_PROTOCOL_VERSION);
            append_u16(&mut out, self.config.manager_client_flags);
            out
        };
        self.send_manager_frame(MCP_MSG_HELLO, &hello).await?;
        let (mut msg_type, mut payload) = self.recv_manager_frame().await?;
        if msg_type != MCP_MSG_STATUS_RESPONSE {
            return Err(Error::new(ErrorKind::Connection, "expected MCP hello status response"));
        }

        let mut auth_start = Vec::new();
        append_lpreface(&mut auth_start, &manager_user);
        auth_start.push(MCP_AUTH_METHOD_TOKEN);
        if self.config.manager_auth_fast_path {
            append_u32(&mut auth_start, self.config.manager_auth_token.len() as u32);
            auth_start.extend_from_slice(self.config.manager_auth_token.as_bytes());
        } else {
            append_u32(&mut auth_start, 0);
        }
        self.send_manager_frame(MCP_MSG_AUTH_START, &auth_start).await?;
        (msg_type, payload) = self.recv_manager_frame().await?;
        if msg_type == MCP_MSG_AUTH_CHALLENGE {
            let mut auth_continue = Vec::new();
            append_u32(&mut auth_continue, self.config.manager_auth_token.len() as u32);
            auth_continue.extend_from_slice(self.config.manager_auth_token.as_bytes());
            self.send_manager_frame(MCP_MSG_AUTH_CONTINUE, &auth_continue).await?;
            (msg_type, payload) = self.recv_manager_frame().await?;
        }
        if msg_type != MCP_MSG_AUTH_RESPONSE {
            return Err(Error::new(ErrorKind::Connection, "expected MCP auth response"));
        }
        if payload.len() < 1 + 4 + 256 {
            return Err(Error::new(ErrorKind::Connection, "truncated MCP auth response"));
        }
        if payload[0] != 0 {
            let mut error_bytes = payload[5..(5 + 256)].to_vec();
            if let Some(pos) = error_bytes.iter().position(|b| *b == 0) {
                error_bytes.truncate(pos);
            }
            let err_text = String::from_utf8_lossy(&error_bytes).to_string();
            return Err(Error::with_sqlstate(
                ErrorKind::Auth,
                if err_text.is_empty() {
                    "MCP authentication failed".to_string()
                } else {
                    err_text
                },
                Some("28000".to_string()),
                None,
                None,
            ));
        }

        let mut db_connect = b"MCP1".to_vec();
        append_lpreface(&mut db_connect, &manager_database);
        append_lpreface(&mut db_connect, &manager_profile);
        append_lpreface(&mut db_connect, &manager_intent);
        let mut nonce = [0u8; 16];
        rand::thread_rng().fill_bytes(&mut nonce);
        append_u16(&mut db_connect, nonce.len() as u16);
        db_connect.extend_from_slice(&nonce);
        self.send_manager_frame(MCP_MSG_DB_CONNECT, &db_connect).await?;
        let (msg_type, payload) = self.recv_manager_frame().await?;
        if msg_type != MCP_MSG_CONNECT_RESPONSE {
            return Err(Error::new(ErrorKind::Connection, "expected MCP connect response"));
        }
        if payload.len() < 1 + 2 + 2 + 16 + 64 + 32 {
            return Err(Error::new(ErrorKind::Connection, "truncated MCP connect response"));
        }
        if payload[0] != 0 {
            let mut err_text = "MCP database connect failed".to_string();
            let err_offset = 1 + 2 + 2 + 16 + 64 + 32;
            if payload.len() >= err_offset + 4 {
                let err_len = u32::from_le_bytes([
                    payload[err_offset],
                    payload[err_offset + 1],
                    payload[err_offset + 2],
                    payload[err_offset + 3],
                ]) as usize;
                if payload.len() >= err_offset + 4 + err_len {
                    err_text = String::from_utf8_lossy(
                        &payload[(err_offset + 4)..(err_offset + 4 + err_len)],
                    )
                    .to_string();
                }
            }
            return Err(Error::with_sqlstate(
                ErrorKind::Auth,
                err_text,
                Some("28000".to_string()),
                None,
                None,
            ));
        }
        Ok(())
    }

    async fn handshake(&mut self, params: HashMap<String, String>) -> Result<()> {
        self.authed = false;
        self.parameters.clear();
        let features = self.requested_features();
        let payload = protocol::build_startup_payload(features, &params);
        self.send_message(protocol::MSG_STARTUP, &payload, 0, true).await?;
        let mut scram: Option<ScramExchange> = None;

        loop {
            let msg = self.recv_message().await?;
            match msg.header.msg_type {
                protocol::MSG_NEGOTIATE_VERSION => continue,
                protocol::MSG_AUTH_REQUEST => {
                    let (method, _data) = protocol::parse_auth_request(&msg.payload)?;
                    match method {
                        protocol::AUTH_OK => continue,
                        protocol::AUTH_PASSWORD => {
                            let payload = self.config.password.as_bytes().to_vec();
                            self.send_message(protocol::MSG_AUTH_RESPONSE, &payload, 0, true).await?;
                        }
                        protocol::AUTH_SCRAM_SHA256 => {
                            if scram.is_none() {
                                scram = Some(ScramExchange::new(&self.config.user));
                            }
                            let exchange = scram.as_mut().unwrap();
                            let payload = exchange.client_first_message().into_bytes();
                            self.send_message(protocol::MSG_AUTH_RESPONSE, &payload, 0, true).await?;
                        }
                        _ => return Err(Error::new(ErrorKind::Auth, "unsupported auth method")),
                    }
                }
                protocol::MSG_AUTH_CONTINUE => {
                    let (method, _stage, data) = protocol::parse_auth_continue(&msg.payload)?;
                    if method != protocol::AUTH_SCRAM_SHA256 {
                        return Err(Error::new(ErrorKind::Auth, "unsupported auth continue"));
                    }
                    let exchange = scram.as_mut().ok_or_else(|| Error::new(ErrorKind::Auth, "SCRAM state missing"))?;
                    let server_first = String::from_utf8_lossy(&data).to_string();
                    let client_final = exchange.handle_server_first(&self.config.password, &server_first)?;
                    self.send_message(protocol::MSG_AUTH_RESPONSE, client_final.as_bytes(), 0, true).await?;
                }
                protocol::MSG_AUTH_OK => {
                    let (_session_id, info) = protocol::parse_auth_ok(&msg.payload)?;
                    self.attachment_id.copy_from_slice(&msg.header.attachment_id);
                    self.apply_txn_state(msg.header.txn_id);
                    self.authed = true;
                    if let Some(ref exchange) = scram {
                        if !info.is_empty() && info.starts_with(b"v=") {
                            let server_final = String::from_utf8_lossy(&info).to_string();
                            exchange.verify_server_final(&server_final)?;
                        }
                    }
                }
                protocol::MSG_PARAMETER_STATUS => {
                    let (name, value) = protocol::parse_parameter_status(&msg.payload)?;
                    self.handle_parameter_status(name, value);
                }
                protocol::MSG_READY => {
                    let (_status, txn_id, _visibility) = protocol::parse_ready(&msg.payload)?;
                    self.apply_txn_state(txn_id);
                    return Ok(());
                }
                protocol::MSG_ERROR => return self.raise_protocol_error(&msg.payload),
                _ => continue,
            }
        }
    }

    async fn apply_schema(&mut self) -> Result<()> {
        let schema = self.config.schema.trim();
        if schema.is_empty() || schema.eq_ignore_ascii_case("public") {
            return Ok(());
        }
        let statement = build_schema_statement(schema);
        if statement.is_empty() {
            return Ok(());
        }
        self.send_simple_query(&statement, 0, 0).await?;
        let _ = self.collect_results().await?;
        Ok(())
    }

    async fn collect_results(&mut self) -> Result<QueryResult> {
        let mut columns = Vec::new();
        let mut rows = Vec::new();
        let mut row_count = -1;
        let mut command_tag = String::new();

        loop {
            let msg = self.recv_message().await?;
            if self.handle_async_message(&msg)? {
                continue;
            }
            match msg.header.msg_type {
                protocol::MSG_ERROR => return self.raise_protocol_error(&msg.payload),
                protocol::MSG_ROW_DESCRIPTION => {
                    columns = protocol::parse_row_description(&msg.payload)?;
                }
                protocol::MSG_DATA_ROW => {
                    let values = protocol::parse_data_row(&msg.payload, columns.len())?;
                    rows.push(self.decode_row(&columns, &values)?);
                }
                protocol::MSG_COMMAND_COMPLETE => {
                    let (_cmd_type, rows_affected, _last_id, tag) = protocol::parse_command_complete(&msg.payload)?;
                    command_tag = tag;
                    row_count = rows_affected as i64;
                }
                protocol::MSG_PORTAL_SUSPENDED => {
                    let rows_to_fetch = self.config.fetch_size.max(1);
                    let payload = protocol::build_execute_payload("", rows_to_fetch);
                    self.send_message(protocol::MSG_EXECUTE, &payload, 0, false).await?;
                }
                protocol::MSG_READY => {
                    let (_status, txn_id, _visibility) = protocol::parse_ready(&msg.payload)?;
                    self.apply_txn_state(txn_id);
                    if row_count < 0 {
                        row_count = rows.len() as i64;
                    }
                    let mapped = columns
                        .into_iter()
                        .map(|col| Column {
                            name: col.name,
                            type_oid: col.type_oid,
                            type_modifier: col.type_modifier,
                            format: col.format,
                            nullable: col.nullable,
                        })
                        .collect();
                    return Ok(QueryResult { columns: mapped, rows, row_count, command_tag });
                }
                _ => continue,
            }
        }
    }

    async fn drain_until_ready(&mut self) -> Result<()> {
        loop {
            let msg = self.recv_message().await?;
            if self.handle_async_message(&msg)? {
                continue;
            }
            match msg.header.msg_type {
                protocol::MSG_READY => {
                    let (_status, txn_id, _visibility) = protocol::parse_ready(&msg.payload)?;
                    self.apply_txn_state(txn_id);
                    return Ok(());
                }
                protocol::MSG_ERROR => return self.raise_protocol_error(&msg.payload),
                _ => continue,
            }
        }
    }

    fn handle_parameter_status(&mut self, name: String, value: String) {
        if name == "attachment_id" {
            if let Some(parsed) = parse_uuid_bytes(&value) {
                self.attachment_id = parsed;
            }
        }
        if name == "current_txn_id" {
            if let Ok(parsed) = value.trim().parse::<u64>() {
                self.apply_txn_state(parsed);
            }
        }
        self.parameters.insert(name, value);
    }

    fn handle_async_message(&mut self, msg: &protocol::Message) -> Result<bool> {
        match msg.header.msg_type {
            protocol::MSG_PARAMETER_STATUS => {
                let (name, value) = protocol::parse_parameter_status(&msg.payload)?;
                self.handle_parameter_status(name, value);
                Ok(true)
            }
            protocol::MSG_NOTIFICATION => {
                let notice = protocol::parse_notification(&msg.payload)?;
                for handler in &self.notification_handlers {
                    handler(&notice);
                }
                Ok(true)
            }
            protocol::MSG_QUERY_PLAN => {
                self.last_plan = Some(protocol::parse_query_plan(&msg.payload)?);
                Ok(true)
            }
            protocol::MSG_SBLR_COMPILED => {
                self.last_sblr = Some(protocol::parse_sblr_compiled(&msg.payload)?);
                Ok(true)
            }
            _ => Ok(false),
        }
    }

    async fn send_simple_query(&mut self, sql: &str, max_rows: u32, timeout_ms: u32) -> Result<()> {
        let flags = if self.config.binary_transfer { QUERY_FLAG_BINARY_RESULT } else { 0 };
        let payload = protocol::build_query_payload(sql, flags, max_rows, timeout_ms);
        self.last_plan = None;
        self.last_sblr = None;
        let sequence = self.send_message(protocol::MSG_QUERY, &payload, 0, false).await?;
        self.last_query_sequence = sequence;
        Ok(())
    }

    async fn send_extended_query(&mut self, sql: &str, params: &[Param], max_rows: u32) -> Result<()> {
        let mut param_values = Vec::with_capacity(params.len());
        let mut param_types = Vec::with_capacity(params.len());
        for param in params {
            let (value, oid) = encode_param(param)?;
            param_values.push(value);
            param_types.push(oid);
        }
        let parse_payload = protocol::build_parse_payload("", sql, &param_types);
        self.send_message(protocol::MSG_PARSE, &parse_payload, 0, false).await?;
        let described = self.describe_statement("").await?;
        if described > 0 && described != params.len() {
            return Err(Error::with_sqlstate(
                ErrorKind::Syntax,
                "parameter count mismatch",
                Some("07001".to_string()),
                None,
                None,
            ));
        }

        let result_formats = if self.config.binary_transfer { vec![FORMAT_BINARY] } else { Vec::new() };
        let bind_payload = protocol::build_bind_payload("", "", &param_values, &result_formats);
        self.send_message(protocol::MSG_BIND, &bind_payload, 0, false).await?;

        let exec_payload = protocol::build_execute_payload("", max_rows);
        self.last_plan = None;
        self.last_sblr = None;
        let sequence = self.send_message(protocol::MSG_EXECUTE, &exec_payload, 0, false).await?;
        self.last_query_sequence = sequence;
        if max_rows == 0 {
            self.send_message(protocol::MSG_SYNC, &[], 0, false).await?;
        }
        Ok(())
    }

    async fn describe_statement(&mut self, statement_name: &str) -> Result<usize> {
        let payload = protocol::build_describe_payload(b'S', statement_name);
        self.send_message(protocol::MSG_DESCRIBE, &payload, 0, false).await?;
        self.send_message(protocol::MSG_SYNC, &[], 0, false).await?;
        let mut param_count = 0usize;
        loop {
            let msg = self.recv_message().await?;
            if self.handle_async_message(&msg)? {
                continue;
            }
            match msg.header.msg_type {
                protocol::MSG_PARAMETER_DESCRIPTION => {
                    let types = protocol::parse_parameter_description(&msg.payload)?;
                    param_count = types.len();
                }
                protocol::MSG_ERROR => return self.raise_protocol_error(&msg.payload),
                protocol::MSG_READY => {
                    let (_status, txn_id, _visibility) = protocol::parse_ready(&msg.payload)?;
                    self.apply_txn_state(txn_id);
                    return Ok(param_count);
                }
                _ => continue,
            }
        }
    }

    async fn connect_transport(&self) -> Result<Box<dyn AsyncReadWrite>> {
        let addr = format!("{}:{}", self.config.host, self.config.port);
        let timeout_ms = self.config.connect_timeout_ms;
        let stream = timeout(Duration::from_millis(timeout_ms), TcpStream::connect(&addr))
            .await
            .map_err(|_| Error::new(ErrorKind::Connection, "connect timeout"))?
            .map_err(|e| Error::new(ErrorKind::Connection, e.to_string()))?;
        stream.set_nodelay(true).ok();

        let sslmode = self.config.sslmode.to_ascii_lowercase();
        if sslmode == "disable" {
            return Ok(Box::new(stream));
        }
        let tls = self.connect_tls(stream).await?;
        Ok(Box::new(tls))
    }

    async fn connect_tls(&self, stream: TcpStream) -> Result<TlsStream<TcpStream>> {
        use rustls::{ClientConfig, RootCertStore};

        let mut root_store = RootCertStore::empty();
        if let Ok(store) = rustls_native_certs::load_native_certs() {
            for cert in store {
                root_store.add(&rustls::Certificate(cert.0)).ok();
            }
        }
        if let Some(ref path) = self.config.sslrootcert {
            let data = std::fs::read(path).map_err(|e| Error::new(ErrorKind::Connection, e.to_string()))?;
            let mut cursor = std::io::Cursor::new(data);
            let certs = rustls_pemfile::certs(&mut cursor).unwrap_or_default();
            for cert in certs {
                root_store.add(&rustls::Certificate(cert)).ok();
            }
        }

        let builder = ClientConfig::builder()
            .with_safe_defaults()
            .with_root_certificates(root_store);

        let mut client_config = if let (Some(cert_path), Some(key_path)) = (&self.config.sslcert, &self.config.sslkey) {
            let cert_bytes = std::fs::read(cert_path).map_err(|e| Error::new(ErrorKind::Connection, e.to_string()))?;
            let key_bytes = std::fs::read(key_path).map_err(|e| Error::new(ErrorKind::Connection, e.to_string()))?;
            let mut cert_cursor = std::io::Cursor::new(cert_bytes);
            let mut key_cursor = std::io::Cursor::new(key_bytes);
            let certs = rustls_pemfile::certs(&mut cert_cursor).unwrap_or_default();
            let mut keys = rustls_pemfile::pkcs8_private_keys(&mut key_cursor).unwrap_or_default();
            if keys.is_empty() {
                key_cursor.set_position(0);
                keys = rustls_pemfile::rsa_private_keys(&mut key_cursor).unwrap_or_default();
            }
            if !certs.is_empty() && !keys.is_empty() {
                builder
                    .with_single_cert(
                        certs.into_iter().map(rustls::Certificate).collect(),
                        rustls::PrivateKey(keys.remove(0)),
                    )
                    .map_err(|e| Error::new(ErrorKind::Connection, e.to_string()))?
            } else {
                builder.with_no_client_auth()
            }
        } else {
            builder.with_no_client_auth()
        };

        let sslmode = self.config.sslmode.to_ascii_lowercase();
        if matches!(sslmode.as_str(), "allow" | "prefer" | "require") {
            client_config
                .dangerous()
                .set_certificate_verifier(Arc::new(NoVerifier));
        }

        let connector = TlsConnector::from(Arc::new(client_config));
        let server_name = rustls::ServerName::try_from(self.config.host.as_str())
            .map_err(|_| Error::new(ErrorKind::Connection, "invalid tls server name"))?;
        let tls = connector.connect(server_name, stream).await.map_err(|e| Error::new(ErrorKind::Connection, e.to_string()))?;
        Ok(tls)
    }

    async fn send_message(&mut self, msg_type: u8, payload: &[u8], flags: u8, force_zero: bool) -> Result<u32> {
        let stream = self.stream.as_mut().ok_or_else(|| Error::new(ErrorKind::Connection, "no active socket"))?;
        let sequence = self.sequence;
        self.sequence = self.sequence.wrapping_add(1);
        let header = MessageHeader {
            msg_type,
            flags,
            length: payload.len() as u32,
            sequence,
            attachment_id: if self.authed && !force_zero { self.attachment_id } else { [0u8; 16] },
            txn_id: if self.authed && !force_zero { self.txn_id } else { 0 },
        };
        let data = protocol::encode_message(&header, payload);
        if self.config.socket_timeout_ms > 0 {
            timeout(Duration::from_millis(self.config.socket_timeout_ms), stream.write_all(&data))
                .await
                .map_err(|_| Error::new(ErrorKind::Connection, "socket write timeout"))??;
        } else {
            stream.write_all(&data).await?;
        }
        Ok(sequence)
    }

    async fn recv_message(&mut self) -> Result<protocol::Message> {
        let mut header_bytes = [0u8; protocol::HEADER_SIZE];
        self.read_exact(&mut header_bytes).await?;
        let header = protocol::decode_header(&header_bytes)?;
        let mut payload = vec![0u8; header.length as usize];
        if header.length > 0 {
            self.read_exact(&mut payload).await?;
        }
        Ok(protocol::Message { header, payload })
    }

    async fn read_exact(&mut self, buf: &mut [u8]) -> Result<()> {
        let stream = self.stream.as_mut().ok_or_else(|| Error::new(ErrorKind::Connection, "no active socket"))?;
        if self.config.socket_timeout_ms > 0 {
            timeout(Duration::from_millis(self.config.socket_timeout_ms), stream.read_exact(buf))
                .await
                .map_err(|_| Error::new(ErrorKind::Connection, "socket read timeout"))??;
        } else {
            stream.read_exact(buf).await?;
        }
        Ok(())
    }

    fn decode_row(&self, columns: &[protocol::ColumnInfo], values: &[protocol::ColumnValue]) -> Result<Vec<Value>> {
        let mut row = Vec::with_capacity(values.len());
        for (idx, value) in values.iter().enumerate() {
            let col = columns.get(idx);
            let type_oid = col.map(|c| c.type_oid).unwrap_or(0);
            let format = col.map(|c| c.format as u16).unwrap_or(FORMAT_BINARY);
            row.push(decode_value(type_oid, value.data.clone(), format)?);
        }
        Ok(row)
    }

    fn raise_protocol_error<T>(&self, payload: &[u8]) -> Result<T> {
        let (_severity, sqlstate, message, detail, hint) = protocol::parse_error_message(payload)?;
        let mut parts = Vec::new();
        if !message.is_empty() {
            parts.push(message.clone());
        }
        if !detail.is_empty() {
            parts.push(format!("DETAIL: {}", detail));
        }
        if !hint.is_empty() {
            parts.push(format!("HINT: {}", hint));
        }
        let combined = if parts.is_empty() { "query failed".to_string() } else { parts.join("\n") };
        Err(error_from_sqlstate(&sqlstate, combined, Some(detail), Some(hint)))
    }

    fn ensure_connected(&self) -> Result<()> {
        if !self.connected {
            return Err(Error::new(ErrorKind::Connection, "client is not connected"));
        }
        Ok(())
    }

    fn has_active_transaction(&self) -> bool {
        self.txn_id != 0
    }

    fn ensure_no_active_transaction(&self) -> Result<()> {
        if self.has_active_transaction() {
            return Err(Self::invalid_txn_state("transaction already active"));
        }
        Ok(())
    }

    fn ensure_transaction_active(&self, operation: &str) -> Result<()> {
        if !self.has_active_transaction() {
            return Err(Self::invalid_txn_state(format!("cannot {} without an active transaction", operation)));
        }
        Ok(())
    }

    fn invalid_txn_state(message: impl Into<String>) -> Error {
        Error::with_sqlstate(
            ErrorKind::Transaction,
            message,
            Some("25000".to_string()),
            None,
            None,
        )
    }

    fn validate_savepoint_name(name: &str) -> Result<&str> {
        let trimmed = name.trim();
        if trimmed.is_empty() {
            return Err(Error::with_sqlstate(
                ErrorKind::Syntax,
                "savepoint name is required",
                Some("42601".to_string()),
                None,
                None,
            ));
        }
        Ok(trimmed)
    }

    fn apply_txn_state(&mut self, txn_id: u64) {
        self.txn_id = txn_id;
    }

    fn requested_features(&self) -> u64 {
        let mut features = 0u64;
        if self.config.compression.eq_ignore_ascii_case("zstd") {
            features |= protocol::FEATURE_COMPRESSION;
        }
        if self.config.binary_transfer {
            features |= protocol::FEATURE_STREAMING;
            features |= protocol::FEATURE_BINARY_COPY;
        }
        features |= protocol::FEATURE_SAVEPOINTS;
        features |= protocol::FEATURE_BATCH;
        features |= protocol::FEATURE_PIPELINE;
        features
    }

    async fn begin_operation(&mut self, name: &str) -> Result<Option<SpanContext>> {
        if !self.circuit_breaker.allow_request().await {
            return Err(Error::new(ErrorKind::Connection, "circuit breaker is OPEN"));
        }
        if self.keepalive_tracker.needs_validation().await {
            self.ping().await?;
        }
        self.keepalive_tracker.mark_active().await;
        Ok(self.telemetry.start_span(name).await)
    }

    async fn end_operation(&self, span: Option<SpanContext>, success: bool) {
        if success {
            self.circuit_breaker.record_success().await;
        } else {
            self.circuit_breaker.record_failure().await;
        }
        if let Some(span) = span {
            self.telemetry.end_span(span, success).await;
        }
    }
}

impl<'a> QueryStream<'a> {
    pub async fn next_row(&mut self) -> Result<Option<Vec<Value>>> {
        if self.done {
            return Ok(None);
        }
        loop {
            let msg = self.client.recv_message().await?;
            if self.client.handle_async_message(&msg)? {
                continue;
            }
            match msg.header.msg_type {
                protocol::MSG_ERROR => {
                    let err = self.client.raise_protocol_error(&msg.payload);
                    self.finalize(false).await;
                    return err;
                }
                protocol::MSG_ROW_DESCRIPTION => {
                    self.columns = protocol::parse_row_description(&msg.payload)?;
                }
                protocol::MSG_DATA_ROW => {
                    let values = protocol::parse_data_row(&msg.payload, self.columns.len())?;
                    let row = self.client.decode_row(&self.columns, &values)?;
                    return Ok(Some(row));
                }
                protocol::MSG_COMMAND_COMPLETE => {
                    let (_cmd_type, rows_affected, _last_id, tag) = protocol::parse_command_complete(&msg.payload)?;
                    self.command_tag = tag;
                    self.row_count = rows_affected as i64;
                }
                protocol::MSG_PORTAL_SUSPENDED => {
                    let payload = protocol::build_execute_payload("", self.page_size);
                    self.client.send_message(protocol::MSG_EXECUTE, &payload, 0, false).await?;
                }
                protocol::MSG_READY => {
                    let (_status, txn_id, _visibility) = protocol::parse_ready(&msg.payload)?;
                    self.client.apply_txn_state(txn_id);
                    self.done = true;
                    self.finalize(true).await;
                    return Ok(None);
                }
                _ => {}
            }
        }
    }

    async fn finalize(&mut self, success: bool) {
        if self.finalized {
            return;
        }
        self.finalized = true;
        if success {
            self.circuit_breaker.record_success().await;
        } else {
            self.circuit_breaker.record_failure().await;
        }
        if let Some(span) = self.span.take() {
            self.telemetry.end_span(span, success).await;
        }
    }

    pub fn columns(&self) -> &[protocol::ColumnInfo] {
        &self.columns
    }

    pub fn row_count(&self) -> i64 {
        self.row_count
    }

    pub fn command_tag(&self) -> &str {
        &self.command_tag
    }
}

struct NoVerifier;

impl rustls::client::ServerCertVerifier for NoVerifier {
    fn verify_server_cert(
        &self,
        _end_entity: &rustls::Certificate,
        _intermediates: &[rustls::Certificate],
        _server_name: &rustls::ServerName,
        _scts: &mut dyn Iterator<Item = &[u8]>,
        _ocsp_response: &[u8],
        _now: std::time::SystemTime,
    ) -> std::result::Result<rustls::client::ServerCertVerified, rustls::Error> {
        Ok(rustls::client::ServerCertVerified::assertion())
    }
}

fn build_schema_statement(schema: &str) -> String {
    let trimmed = schema.trim();
    if trimmed.is_empty() {
        return String::new();
    }
    if trimmed.contains(',') {
        let parts: Vec<String> = trimmed
            .split(',')
            .map(|part| part.trim())
            .filter(|part| !part.is_empty())
            .map(quote_identifier)
            .collect();
        if parts.is_empty() {
            return String::new();
        }
        return format!("SET SEARCH_PATH TO {}", parts.join(", "));
    }
    format!("SET SCHEMA {}", quote_identifier(trimmed))
}

fn quote_identifier(name: &str) -> String {
    format!("\"{}\"", name.replace('"', "\"\""))
}

fn parse_uuid_bytes(value: &str) -> Option<[u8; 16]> {
    let hex: String = value.chars().filter(|c| *c != '-').collect();
    if hex.len() != 32 || !hex.chars().all(|c| c.is_ascii_hexdigit()) {
        return None;
    }
    let mut bytes = [0u8; 16];
    for i in 0..16 {
        let start = i * 2;
        let part = &hex[start..start + 2];
        if let Ok(byte) = u8::from_str_radix(part, 16) {
            bytes[i] = byte;
        } else {
            return None;
        }
    }
    Some(bytes)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn preflight_connect_requires_manager_auth_token() {
        let mut cfg = Config::default();
        cfg.user = "tester".to_string();
        cfg.database = "db".to_string();
        cfg.front_door_mode = "manager_proxy".to_string();
        let mut client = Client::new(cfg);
        let err = client.preflight_connect().unwrap_err();
        assert_eq!(err.kind, ErrorKind::Connection);
        assert_eq!(err.message, "manager_proxy mode requires manager_auth_token");
    }

    #[test]
    fn build_startup_params_includes_auth_plugin_selection() {
        let mut cfg = Config::default();
        cfg.user = "tester".to_string();
        cfg.database = "db".to_string();
        cfg.extra.insert(
            protocol::AUTH_PARAM_METHOD_ID.to_string(),
            "scratchbird.auth.password".to_string(),
        );
        cfg.extra.insert(
            protocol::AUTH_PARAM_PAYLOAD_JSON.to_string(),
            "{\"tenant\":\"alpha\"}".to_string(),
        );
        cfg.extra.insert(
            protocol::AUTH_PARAM_PAYLOAD_B64.to_string(),
            "dGVzdA==".to_string(),
        );
        cfg.extra.insert(
            protocol::AUTH_PARAM_PROVIDER_PROFILE.to_string(),
            "default".to_string(),
        );
        let client = Client::new(cfg);
        let params = client.build_startup_params().unwrap();

        assert_eq!(params.get("database").map(String::as_str), Some("db"));
        assert_eq!(params.get("user").map(String::as_str), Some("tester"));
        assert_eq!(
            params.get(protocol::AUTH_PARAM_METHOD_ID).map(String::as_str),
            Some("scratchbird.auth.password")
        );
        assert_eq!(
            params
                .get(protocol::AUTH_PARAM_PAYLOAD_JSON)
                .map(String::as_str),
            Some("{\"tenant\":\"alpha\"}")
        );
        assert_eq!(
            params.get(protocol::AUTH_PARAM_PAYLOAD_B64).map(String::as_str),
            Some("dGVzdA==")
        );
        assert_eq!(
            params
                .get(protocol::AUTH_PARAM_PROVIDER_PROFILE)
                .map(String::as_str),
            Some("default")
        );
    }

    #[test]
    fn build_startup_params_rejects_invalid_auth_method_namespace() {
        let mut cfg = Config::default();
        cfg.user = "tester".to_string();
        cfg.database = "db".to_string();
        cfg.extra.insert(
            protocol::AUTH_PARAM_METHOD_ID.to_string(),
            "custom.invalid".to_string(),
        );
        let client = Client::new(cfg);
        let err = client.build_startup_params().unwrap_err();
        assert_eq!(err.kind, ErrorKind::Auth);
        assert_eq!(err.message, "invalid auth_method_id namespace");
    }

    #[test]
    fn native_sql_rewrites_named_placeholders() {
        let client = Client::new(Config::default());
        let mut params = HashMap::new();
        params.insert("a".to_string(), Param::from(1_i32));
        params.insert("b".to_string(), Param::from(2_i32));

        let sql = client
            .native_sql("SELECT :a, @b", Params::Named(params))
            .unwrap();

        assert_eq!(sql, "SELECT $1, $2");
    }

    #[test]
    fn transaction_state_guards_enforce_begin_commit_rules() {
        let mut client = Client::new(Config::default());

        let err = client.ensure_transaction_active("commit").unwrap_err();
        assert_eq!(err.kind, ErrorKind::Transaction);
        assert_eq!(err.sqlstate.as_deref(), Some("25000"));
        assert_eq!(err.message, "cannot commit without an active transaction");

        client.apply_txn_state(42);
        let err = client.ensure_no_active_transaction().unwrap_err();
        assert_eq!(err.kind, ErrorKind::Transaction);
        assert_eq!(err.sqlstate.as_deref(), Some("25000"));
        assert_eq!(err.message, "transaction already active");
    }

    #[test]
    fn savepoint_name_validation_rejects_blank() {
        let err = Client::validate_savepoint_name("   ").unwrap_err();
        assert_eq!(err.kind, ErrorKind::Syntax);
        assert_eq!(err.sqlstate.as_deref(), Some("42601"));
        assert_eq!(err.message, "savepoint name is required");

        let name = Client::validate_savepoint_name("  sp_a  ").unwrap();
        assert_eq!(name, "sp_a");
    }

    #[test]
    fn metadata_collection_name_rejects_unknown_collection() {
        let err = Client::metadata_collection_name("not_a_collection").unwrap_err();
        assert_eq!(err.kind, ErrorKind::NotSupported);
        assert_eq!(err.sqlstate.as_deref(), Some("0A000"));
    }

    #[tokio::test]
    async fn query_metadata_rejects_unknown_collection_before_connect() {
        let mut client = Client::new(Config::default());
        let err = client.query_metadata("bad_collection").await.unwrap_err();
        assert_eq!(err.kind, ErrorKind::NotSupported);
        assert_eq!(err.sqlstate.as_deref(), Some("0A000"));
    }

    #[tokio::test]
    async fn query_metadata_requires_connected_client_for_supported_collection() {
        let mut client = Client::new(Config::default());
        let err = client.query_metadata("schemas").await.unwrap_err();
        assert_eq!(err.kind, ErrorKind::Connection);
        assert_eq!(err.message, "client is not connected");
    }
}
