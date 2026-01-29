use std::collections::HashMap;
use url::Url;

use crate::errors::{Error, ErrorKind, Result};

#[derive(Debug, Clone)]
pub struct Config {
    pub host: String,
    pub port: u16,
    pub database: String,
    pub user: String,
    pub password: String,
    pub schema: String,
    pub sslmode: String,
    pub sslrootcert: Option<String>,
    pub sslcert: Option<String>,
    pub sslkey: Option<String>,
    pub connect_timeout_ms: u64,
    pub socket_timeout_ms: u64,
    pub application_name: String,
    pub binary_transfer: bool,
    pub compression: String,
    pub extra: HashMap<String, String>,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            host: "localhost".to_string(),
            port: 3092,
            database: String::new(),
            user: String::new(),
            password: String::new(),
            schema: String::new(),
            sslmode: "require".to_string(),
            sslrootcert: None,
            sslcert: None,
            sslkey: None,
            connect_timeout_ms: 30_000,
            socket_timeout_ms: 0,
            application_name: "scratchbird_rust".to_string(),
            binary_transfer: true,
            compression: "off".to_string(),
            extra: HashMap::new(),
        }
    }
}

impl Config {
    pub fn from_dsn(dsn: &str) -> Result<Self> {
        let mut cfg = Config::default();
        let trimmed = dsn.trim();
        if trimmed.is_empty() {
            return Ok(cfg);
        }
        if trimmed.contains("://") {
            Self::parse_uri(trimmed, &mut cfg)?;
        } else {
            Self::parse_key_value(trimmed, &mut cfg);
        }
        Ok(cfg)
    }

    fn parse_uri(dsn: &str, cfg: &mut Config) -> Result<()> {
        let url = Url::parse(dsn).map_err(|e| Error::new(ErrorKind::Connection, e.to_string()))?;
        if url.scheme() != "scratchbird" {
            return Err(Error::new(ErrorKind::Connection, "unsupported DSN scheme"));
        }
        if let Some(host) = url.host_str() {
            cfg.host = host.to_string();
        }
        if let Some(port) = url.port() {
            cfg.port = port;
        }
        if !url.username().is_empty() {
            cfg.user = url.username().to_string();
        }
        if let Some(password) = url.password() {
            cfg.password = password.to_string();
        }
        let path = url.path().trim_start_matches('/');
        if !path.is_empty() {
            cfg.database = path.to_string();
        }
        for (key, value) in url.query_pairs() {
            apply_param(cfg, &key, &value);
        }
        Ok(())
    }

    fn parse_key_value(dsn: &str, cfg: &mut Config) {
        let separator = if dsn.contains(';') { ';' } else { ' ' };
        for token in dsn.split(separator) {
            let token = token.trim();
            if token.is_empty() {
                continue;
            }
            let mut iter = token.splitn(2, '=');
            let key = iter.next().unwrap_or("").trim();
            let value = iter.next().unwrap_or("").trim().trim_matches('"');
            if key.is_empty() {
                continue;
            }
            apply_param(cfg, key, value);
        }
    }
}

fn apply_param(cfg: &mut Config, key: &str, value: &str) {
    match key.to_ascii_lowercase().as_str() {
        "host" | "server" | "data source" | "datasource" => cfg.host = value.to_string(),
        "port" => cfg.port = value.parse().unwrap_or(cfg.port),
        "database" | "dbname" | "initial catalog" => cfg.database = value.to_string(),
        "user" | "username" | "user id" | "uid" => cfg.user = value.to_string(),
        "password" | "pwd" => cfg.password = value.to_string(),
        "schema" | "search_path" | "searchpath" | "currentschema" => cfg.schema = value.to_string(),
        "sslmode" | "ssl mode" => cfg.sslmode = value.to_string(),
        "sslrootcert" => cfg.sslrootcert = Some(value.to_string()),
        "sslcert" => cfg.sslcert = Some(value.to_string()),
        "sslkey" => cfg.sslkey = Some(value.to_string()),
        "connect_timeout" | "connecttimeout" | "timeout" => {
            if let Ok(seconds) = value.parse::<u64>() {
                cfg.connect_timeout_ms = seconds * 1000;
            }
        }
        "socket_timeout" | "sockettimeout" => {
            if let Ok(seconds) = value.parse::<u64>() {
                cfg.socket_timeout_ms = seconds * 1000;
            }
        }
        "application_name" | "applicationname" => cfg.application_name = value.to_string(),
        "binary_transfer" | "binarytransfer" => {
            cfg.binary_transfer = matches!(value, "1" | "true" | "TRUE");
        }
        "compression" => {
            cfg.compression = if value.eq_ignore_ascii_case("zstd") {
                "zstd".to_string()
            } else {
                "off".to_string()
            };
        }
        other => {
            cfg.extra.insert(other.to_string(), value.to_string());
        }
    }
}
