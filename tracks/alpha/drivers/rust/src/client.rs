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

use tokio::io::{AsyncRead, AsyncReadExt, AsyncWrite, AsyncWriteExt};
use tokio::net::TcpStream;
use tokio::time::timeout;
use tokio_rustls::client::TlsStream;
use tokio_rustls::TlsConnector;

use crate::config::Config;
use crate::errors::{error_from_sqlstate, Error, ErrorKind, Result};
use crate::protocol;
use crate::protocol::MessageHeader;
use crate::scram::ScramExchange;
use crate::sql::{normalize, Params};
use crate::types::{decode_value, encode_param, Column, Param, Value, FORMAT_BINARY};

const QUERY_FLAG_BINARY_RESULT: u32 = 0x04;

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
}

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
        }
    }

    pub async fn connect(&mut self) -> Result<()> {
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
        let stream = self.connect_transport().await?;
        self.stream = Some(stream);
        self.handshake().await?;
        self.apply_schema().await?;
        self.connected = true;
        Ok(())
    }

    pub async fn close(&mut self) {
        if let Some(mut stream) = self.stream.take() {
            let _ = stream.shutdown().await;
        }
        self.connected = false;
        self.authed = false;
        self.sequence = 0;
    }

    pub async fn query(&mut self, sql: &str) -> Result<QueryResult> {
        self.query_params(sql, Params::Positional(Vec::new())).await
    }

    pub async fn query_params(&mut self, sql: &str, params: Params) -> Result<QueryResult> {
        self.ensure_connected()?;
        let normalized = normalize(sql, params)?;
        if normalized.params.is_empty() {
            self.send_simple_query(&normalized.sql, 0, 0).await?;
        } else {
            self.send_extended_query(&normalized.sql, &normalized.params, 0).await?;
        }
        self.collect_results().await
    }

    pub async fn query_stream(&mut self, sql: &str) -> Result<QueryStream<'_>> {
        self.ensure_connected()?;
        let page_size = self.config.fetch_size;
        self.send_simple_query(sql, page_size, 0).await?;
        Ok(QueryStream {
            client: self,
            columns: Vec::new(),
            row_count: -1,
            command_tag: String::new(),
            done: false,
            page_size,
        })
    }

    pub async fn query_stream_params(&mut self, sql: &str, params: Params) -> Result<QueryStream<'_>> {
        self.ensure_connected()?;
        let normalized = normalize(sql, params)?;
        let page_size = self.config.fetch_size;
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
        let flags = options.map(|opt| opt.flags).unwrap_or(0);
        let payload = protocol::build_txn_commit_payload(flags);
        self.send_message(protocol::MSG_TXN_COMMIT, &payload, 0, false).await?;
        self.drain_until_ready().await
    }

    pub async fn rollback_transaction(&mut self, options: Option<TxnEndOptions>) -> Result<()> {
        self.ensure_connected()?;
        let flags = options.map(|opt| opt.flags).unwrap_or(0);
        let payload = protocol::build_txn_rollback_payload(flags);
        self.send_message(protocol::MSG_TXN_ROLLBACK, &payload, 0, false).await?;
        self.drain_until_ready().await
    }

    pub async fn savepoint(&mut self, name: &str) -> Result<()> {
        self.ensure_connected()?;
        let payload = protocol::build_txn_savepoint_payload(name);
        self.send_message(protocol::MSG_TXN_SAVEPOINT, &payload, 0, false).await?;
        self.drain_until_ready().await
    }

    pub async fn release_savepoint(&mut self, name: &str) -> Result<()> {
        self.ensure_connected()?;
        let payload = protocol::build_txn_release_payload(name);
        self.send_message(protocol::MSG_TXN_RELEASE, &payload, 0, false).await?;
        self.drain_until_ready().await
    }

    pub async fn rollback_to_savepoint(&mut self, name: &str) -> Result<()> {
        self.ensure_connected()?;
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
                    self.txn_id = txn_id;
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
        self.collect_results().await
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

    pub async fn cancel(&mut self) -> Result<()> {
        let payload = protocol::build_cancel_payload(0, self.last_query_sequence);
        self.send_message(protocol::MSG_CANCEL, &payload, protocol::MSG_FLAG_URGENT, false)
            .await
            .map(|_| ())
    }

    async fn handshake(&mut self) -> Result<()> {
        self.authed = false;
        self.parameters.clear();
        let features = self.requested_features();
        let mut params = HashMap::new();
        params.insert("database".to_string(), self.config.database.clone());
        params.insert("user".to_string(), self.config.user.clone());
        if !self.config.role.is_empty() {
            params.insert("role".to_string(), self.config.role.clone());
        }
        if !self.config.application_name.is_empty() {
            params.insert("application_name".to_string(), self.config.application_name.clone());
        }
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
                    self.txn_id = msg.header.txn_id;
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
                    self.txn_id = txn_id;
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
                protocol::MSG_READY => {
                    let (_status, txn_id, _visibility) = protocol::parse_ready(&msg.payload)?;
                    self.txn_id = txn_id;
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
                    self.txn_id = txn_id;
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
                self.txn_id = parsed;
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
                    self.txn_id = txn_id;
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
            return Err(Error::new(ErrorKind::Connection, "TLS is required"));
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

    fn requested_features(&self) -> u64 {
        let mut features = 0u64;
        if self.config.compression.eq_ignore_ascii_case("zstd") {
            features |= protocol::FEATURE_COMPRESSION;
        }
        if self.config.binary_transfer {
            features |= protocol::FEATURE_STREAMING;
        }
        features
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
                protocol::MSG_ERROR => return self.client.raise_protocol_error(&msg.payload),
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
                    self.client.txn_id = txn_id;
                    self.done = true;
                    return Ok(None);
                }
                _ => {}
            }
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
