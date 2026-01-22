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
use crate::scram::ScramExchange;
use crate::sql::{substitute, Params};
use crate::types::{decode_value, Column, Value, WireType};

pub struct Client {
    config: Config,
    stream: Option<Box<dyn AsyncReadWrite>>,
    session_id: Option<[u8; 16]>,
    server_name: String,
    server_version: String,
    connected: bool,
    autocommit: bool,
    in_transaction: bool,
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
    rowcount: i64,
    rowcount_hint: i64,
    command_tag: String,
    done: bool,
}

trait AsyncReadWrite: AsyncRead + AsyncWrite + Unpin + Send {}
impl<T> AsyncReadWrite for T where T: AsyncRead + AsyncWrite + Unpin + Send {}

impl Client {
    pub fn new(config: Config) -> Self {
        Self {
            config,
            stream: None,
            session_id: None,
            server_name: String::new(),
            server_version: String::new(),
            connected: false,
            autocommit: true,
            in_transaction: false,
        }
    }

    pub fn server_name(&self) -> &str {
        &self.server_name
    }

    pub fn server_version(&self) -> &str {
        &self.server_version
    }

    pub fn set_autocommit(&mut self, value: bool) {
        self.autocommit = value;
    }

    pub async fn connect(&mut self) -> Result<()> {
        if self.config.user.is_empty() || self.config.database.is_empty() {
            return Err(Error::new(ErrorKind::Connection, "user and database are required"));
        }
        let stream = self.connect_transport().await?;
        self.stream = Some(stream);
        self.handshake().await?;
        self.authenticate().await?;
        self.connected = true;
        Ok(())
    }

    pub async fn close(&mut self) {
        if let Some(mut stream) = self.stream.take() {
            let _ = stream.shutdown().await;
        }
        self.connected = false;
        self.session_id = None;
        self.in_transaction = false;
    }

    pub async fn disconnect(&mut self) {
        if self.connected {
            if let Some(session_id) = self.session_id {
                let msg = protocol::build_disconnect(&session_id);
                let _ = self.send_message(&msg).await;
            }
        }
        self.close().await;
    }

    pub async fn begin(&mut self) -> Result<()> {
        if self.in_transaction {
            return Ok(());
        }
        let session_id = self.session_id.ok_or_else(|| Error::new(ErrorKind::Connection, "no session id"))?;
        let msg = protocol::build_begin(&session_id, 0, false);
        self.send_message(&msg).await?;
        self.drain_until_complete().await?;
        self.in_transaction = true;
        Ok(())
    }

    pub async fn commit(&mut self) -> Result<()> {
        if !self.in_transaction {
            return Ok(());
        }
        let session_id = self.session_id.ok_or_else(|| Error::new(ErrorKind::Connection, "no session id"))?;
        let msg = protocol::build_commit(&session_id);
        self.send_message(&msg).await?;
        self.drain_until_complete().await?;
        self.in_transaction = false;
        Ok(())
    }

    pub async fn rollback(&mut self) -> Result<()> {
        if !self.in_transaction {
            return Ok(());
        }
        let session_id = self.session_id.ok_or_else(|| Error::new(ErrorKind::Connection, "no session id"))?;
        let msg = protocol::build_rollback(&session_id);
        self.send_message(&msg).await?;
        self.drain_until_complete().await?;
        self.in_transaction = false;
        Ok(())
    }

    pub async fn query(&mut self, sql: &str) -> Result<QueryResult> {
        self.query_params(sql, Params::Positional(Vec::new())).await
    }

    pub async fn query_params(&mut self, sql: &str, params: Params) -> Result<QueryResult> {
        self.ensure_connected()?;
        if !self.autocommit {
            self.begin().await?;
        }
        let rendered = substitute(sql, params);
        self.send_query(&rendered).await
    }

    pub async fn query_stream(&mut self, sql: &str) -> Result<QueryStream<'_>> {
        self.ensure_connected()?;
        if !self.autocommit {
            self.begin().await?;
        }
        let session_id = self.session_id.ok_or_else(|| Error::new(ErrorKind::Connection, "no session id"))?;
        let msg = protocol::build_query(&session_id, sql, 0);
        self.send_message(&msg).await?;
        Ok(QueryStream {
            client: self,
            columns: Vec::new(),
            rowcount: -1,
            rowcount_hint: -1,
            command_tag: String::new(),
            done: false,
        })
    }

    async fn send_query(&mut self, sql: &str) -> Result<QueryResult> {
        let session_id = self.session_id.ok_or_else(|| Error::new(ErrorKind::Connection, "no session id"))?;
        let msg = protocol::build_query(&session_id, sql, 0);
        self.send_message(&msg).await?;
        let mut columns = Vec::new();
        let mut rows = Vec::new();
        let mut rowcount = -1;
        let mut rowcount_hint = -1;
        let mut command_tag = String::new();

        loop {
            let (msg_type, payload) = self.recv_message().await?;
            match msg_type {
                protocol::MSG_QUERY_ERROR => return self.raise_query_error(&payload),
                protocol::MSG_QUERY_RESULT => {
                    let (_, _, rows_hint) = protocol::parse_query_result(&payload)?;
                    rowcount_hint = rows_hint;
                }
                protocol::MSG_ROW_DESCRIPTION => {
                    columns = protocol::parse_row_description(&payload)?;
                }
                protocol::MSG_ROW_DATA => {
                    let values = protocol::parse_row_data(&payload)?;
                    rows.push(self.decode_row(&columns, &values)?);
                }
                protocol::MSG_COMMAND_COMPLETE => {
                    let (tag, rows_affected) = protocol::parse_command_complete(&payload)?;
                    command_tag = tag;
                    rowcount = rows_affected;
                }
                protocol::MSG_END_RESULTS => break,
                _ => {}
            }
        }

        if rowcount < 0 && rowcount_hint >= 0 {
            rowcount = rowcount_hint;
        }
        if rowcount < 0 {
            rowcount = rows.len() as i64;
        }

        Ok(QueryResult {
            columns: columns
                .into_iter()
                .map(|col| Column {
                    name: col.name,
                    wire_type: WireType::from(col.wire_type),
                    type_modifier: col.type_modifier,
                    format: col.format,
                })
                .collect(),
            rows,
            row_count: rowcount,
            command_tag,
        })
    }

    async fn handshake(&mut self) -> Result<()> {
        let msg = protocol::build_connect_request(
            &self.config.database,
            &self.config.application_name,
            std::process::id(),
        );
        self.send_message(&msg).await?;
        let (msg_type, payload) = self.recv_message().await?;
        if msg_type != protocol::MSG_CONNECT_RESPONSE {
            return Err(Error::new(ErrorKind::Connection, "unexpected response to CONNECT_REQUEST"));
        }
        let (success, session_id, server_name, server_version, error_msg) =
            protocol::parse_connect_response(&payload)?;
        if !success {
            return Err(Error::new(
                ErrorKind::Connection,
                if error_msg.is_empty() { "connect failed" } else { &error_msg },
            ));
        }
        self.session_id = Some(session_id);
        self.server_name = server_name;
        self.server_version = server_version;
        Ok(())
    }

    async fn authenticate(&mut self) -> Result<()> {
        let session_id = self.session_id.ok_or_else(|| Error::new(ErrorKind::Auth, "missing session"))?;
        let mut exchange = ScramExchange::new(&self.config.user);
        let client_first = exchange.client_first_message();
        let msg = protocol::build_auth_request(&session_id, &self.config.user, protocol::AUTH_SCRAM_SHA256, client_first.as_bytes());
        self.send_message(&msg).await?;
        let (msg_type, payload) = self.recv_message().await?;
        if msg_type != protocol::MSG_AUTH_RESPONSE {
            return Err(Error::new(ErrorKind::Auth, "unexpected response to AUTH_REQUEST"));
        }
        let (status, _user_id, error_msg, extra) = protocol::parse_auth_response(&payload)?;
        if status != 2 {
            return Err(Error::new(ErrorKind::Auth, if error_msg.is_empty() { "auth failed" } else { &error_msg }));
        }
        let server_first = String::from_utf8_lossy(&extra).to_string();
        let client_final = exchange.handle_server_first(&self.config.password, &server_first)?;
        let msg = protocol::build_auth_request(&session_id, &self.config.user, protocol::AUTH_SCRAM_SHA256, client_final.as_bytes());
        self.send_message(&msg).await?;
        let (msg_type, payload) = self.recv_message().await?;
        if msg_type != protocol::MSG_AUTH_RESPONSE {
            return Err(Error::new(ErrorKind::Auth, "unexpected response to SCRAM final"));
        }
        let (status, _user_id, error_msg, extra) = protocol::parse_auth_response(&payload)?;
        if status != 0 {
            return Err(Error::new(ErrorKind::Auth, if error_msg.is_empty() { "auth failed" } else { &error_msg }));
        }
        if !extra.is_empty() {
            let server_final = String::from_utf8_lossy(&extra);
            exchange.verify_server_final(&server_final)?;
        }
        Ok(())
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

        let require_tls = matches!(sslmode.as_str(), "require" | "verify-ca" | "verify-full");
        match self.connect_tls(stream).await {
            Ok(tls) => Ok(Box::new(tls)),
            Err(err) => {
                if matches!(sslmode.as_str(), "allow" | "prefer") {
                    let fallback = TcpStream::connect(&addr).await?;
                    fallback.set_nodelay(true).ok();
                    Ok(Box::new(fallback))
                } else if require_tls {
                    Err(err)
                } else {
                    Ok(Box::new(TcpStream::connect(&addr).await?))
                }
            }
        }
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

        let sslmode = self.config.sslmode.to_ascii_lowercase();
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

    async fn send_message(&mut self, data: &[u8]) -> Result<()> {
        let stream = self.stream.as_mut().ok_or_else(|| Error::new(ErrorKind::Connection, "no active socket"))?;
        if self.config.socket_timeout_ms > 0 {
            timeout(Duration::from_millis(self.config.socket_timeout_ms), stream.write_all(data))
                .await
                .map_err(|_| Error::new(ErrorKind::Connection, "socket write timeout"))??;
        } else {
            stream.write_all(data).await?;
        }
        Ok(())
    }

    async fn recv_message(&mut self) -> Result<(u8, Vec<u8>)> {
        let mut header = [0u8; 12];
        self.read_exact(&mut header).await?;
        let (msg_type, _flags, length) = protocol::decode_header(&header)?;
        let mut payload = vec![0u8; length as usize];
        if length > 0 {
            self.read_exact(&mut payload).await?;
        }
        Ok((msg_type, payload))
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

    async fn drain_until_complete(&mut self) -> Result<()> {
        loop {
            let (msg_type, payload) = self.recv_message().await?;
            if msg_type == protocol::MSG_QUERY_ERROR {
                return self.raise_query_error(&payload);
            }
            if msg_type == protocol::MSG_COMMAND_COMPLETE || msg_type == protocol::MSG_END_RESULTS {
                return Ok(());
            }
        }
    }

    fn decode_row(&self, columns: &[protocol::ColumnInfo], values: &[protocol::ColumnValue]) -> Result<Vec<Value>> {
        let mut row = Vec::with_capacity(values.len());
        for (idx, value) in values.iter().enumerate() {
            let wire_type = columns.get(idx).map(|c| c.wire_type).unwrap_or(WireType::Unknown as u8);
            row.push(decode_value(wire_type, value.data.clone())?);
        }
        Ok(row)
    }

    fn raise_query_error<T>(&self, payload: &[u8]) -> Result<T> {
        let (_code, sqlstate, message, detail, hint) = protocol::parse_query_error(payload)?;
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
        let combined = if parts.is_empty() {
            "query failed".to_string()
        } else {
            parts.join("\n")
        };
        Err(error_from_sqlstate(&sqlstate, combined, Some(detail), Some(hint)))
    }

    fn ensure_connected(&self) -> Result<()> {
        if !self.connected || self.session_id.is_none() {
            return Err(Error::new(ErrorKind::Connection, "client is not connected"));
        }
        Ok(())
    }
}

impl<'a> QueryStream<'a> {
    pub async fn next_row(&mut self) -> Result<Option<Vec<Value>>> {
        if self.done {
            return Ok(None);
        }
        loop {
            let (msg_type, payload) = self.client.recv_message().await?;
            match msg_type {
                protocol::MSG_QUERY_ERROR => return self.client.raise_query_error(&payload),
                protocol::MSG_QUERY_RESULT => {
                    let (_, _, rows_hint) = protocol::parse_query_result(&payload)?;
                    self.rowcount_hint = rows_hint;
                }
                protocol::MSG_ROW_DESCRIPTION => {
                    self.columns = protocol::parse_row_description(&payload)?;
                }
                protocol::MSG_ROW_DATA => {
                    let values = protocol::parse_row_data(&payload)?;
                    let row = self.client.decode_row(&self.columns, &values)?;
                    return Ok(Some(row));
                }
                protocol::MSG_COMMAND_COMPLETE => {
                    let (tag, rows_affected) = protocol::parse_command_complete(&payload)?;
                    self.command_tag = tag;
                    self.rowcount = rows_affected;
                }
                protocol::MSG_END_RESULTS => {
                    if self.rowcount < 0 && self.rowcount_hint >= 0 {
                        self.rowcount = self.rowcount_hint;
                    }
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
        self.rowcount
    }

    pub fn command_tag(&self) -> &str {
        &self.command_tag
    }
}

impl From<u8> for WireType {
    fn from(value: u8) -> Self {
        match value {
            0x01 => WireType::Bool,
            0x02 => WireType::Int16,
            0x03 => WireType::Int32,
            0x04 => WireType::Int64,
            0x05 => WireType::Float32,
            0x06 => WireType::Float64,
            0x07 => WireType::Decimal,
            0x08 => WireType::Varchar,
            0x09 => WireType::Char,
            0x0A => WireType::Bytea,
            0x0B => WireType::Date,
            0x0C => WireType::Time,
            0x0D => WireType::Timestamp,
            0x0E => WireType::TimestampTz,
            0x0F => WireType::Interval,
            0x10 => WireType::Uuid,
            0x11 => WireType::Json,
            0x12 => WireType::Jsonb,
            0x13 => WireType::Array,
            0x16 => WireType::Vector,
            0x17 => WireType::Money,
            0x18 => WireType::Xml,
            0x19 => WireType::Inet,
            0x1A => WireType::Cidr,
            0x1C => WireType::TsVector,
            0x1D => WireType::TsQuery,
            _ => WireType::Unknown,
        }
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
