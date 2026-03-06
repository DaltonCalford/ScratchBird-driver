// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
use std::collections::HashMap;
use url::Url;

use crate::errors::{Error, ErrorKind, Result};

#[derive(Debug, Clone)]
pub struct Config {
    pub host: String,
    pub port: u16,
    pub front_door_mode: String,
    pub protocol: String,
    pub database: String,
    pub user: String,
    pub password: String,
    pub schema: String,
    pub role: String,
    pub sslmode: String,
    pub sslrootcert: Option<String>,
    pub sslcert: Option<String>,
    pub sslkey: Option<String>,
    pub sslpassword: Option<String>,
    pub connect_timeout_ms: u64,
    pub socket_timeout_ms: u64,
    pub application_name: String,
    pub binary_transfer: bool,
    pub compression: String,
    pub fetch_size: u32,
    pub manager_auth_token: String,
    pub manager_username: String,
    pub manager_database: String,
    pub manager_connection_profile: String,
    pub manager_client_intent: String,
    pub manager_client_flags: u16,
    pub manager_auth_fast_path: bool,
    pub metadata_expand_schema_parents: bool,
    pub extra: HashMap<String, String>,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            host: "localhost".to_string(),
            port: 3092,
            front_door_mode: "direct".to_string(),
            protocol: "native".to_string(),
            database: String::new(),
            user: String::new(),
            password: String::new(),
            schema: String::new(),
            role: String::new(),
            sslmode: "require".to_string(),
            sslrootcert: None,
            sslcert: None,
            sslkey: None,
            sslpassword: None,
            connect_timeout_ms: 30_000,
            socket_timeout_ms: 0,
            application_name: "scratchbird_rust".to_string(),
            binary_transfer: true,
            compression: "off".to_string(),
            fetch_size: 0,
            manager_auth_token: String::new(),
            manager_username: String::new(),
            manager_database: String::new(),
            manager_connection_profile: "native_v3".to_string(),
            manager_client_intent: "native_v3".to_string(),
            manager_client_flags: 0,
            manager_auth_fast_path: true,
            metadata_expand_schema_parents: false,
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
            Self::parse_key_value(trimmed, &mut cfg)?;
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
            apply_param(cfg, &key, &value)?;
        }
        Ok(())
    }

    fn parse_key_value(dsn: &str, cfg: &mut Config) -> Result<()> {
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
            apply_param(cfg, key, value)?;
        }
        Ok(())
    }
}

fn normalize_native_protocol(value: &str) -> Option<&'static str> {
    match value.trim().to_ascii_lowercase().as_str() {
        "" | "native" | "scratchbird" | "scratchbird-native" | "scratchbird_native" | "sbwp"
        | "postgres" | "postgresql" | "pg" | "jdbc" | "odbc" | "sql" | "mysql" | "mariadb"
        | "sqlite" | "duckdb" | "firebird" => Some("native"),
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

fn normalize_ssl_mode(value: &str) -> Option<&'static str> {
    match value.trim().to_ascii_lowercase().as_str() {
        "" | "require" | "on" | "true" | "1" | "yes" | "allow" | "prefer" => Some("require"),
        "verify-ca" | "verifyca" => Some("verify-ca"),
        "verify-full" | "verifyfull" => Some("verify-full"),
        "disable" | "off" | "false" | "0" | "no" => Some("disable"),
        _ => None,
    }
}

fn normalize_compression_mode(value: &str) -> Option<&'static str> {
    match value.trim().to_ascii_lowercase().as_str() {
        "" | "off" | "none" | "false" | "0" | "no" => Some("off"),
        "zstd" | "on" | "true" | "1" | "yes" => Some("zstd"),
        _ => None,
    }
}

fn parse_bool_param(value: &str) -> bool {
    matches!(
        value.trim().to_ascii_lowercase().as_str(),
        "1" | "true" | "yes" | "on"
    )
}

fn apply_param(cfg: &mut Config, key: &str, value: &str) -> Result<()> {
    match key.to_ascii_lowercase().as_str() {
        "host" | "server" | "data source" | "datasource" => cfg.host = value.to_string(),
        "port" => cfg.port = value.parse().unwrap_or(cfg.port),
        "front_door_mode" | "frontdoormode" | "connection_mode" | "ingress_mode" => {
            let normalized = normalize_front_door_mode(value).ok_or_else(|| {
                Error::new(
                    ErrorKind::Connection,
                    "front_door_mode must be direct or manager_proxy",
                )
            })?;
            cfg.front_door_mode = normalized.to_string();
        }
        "database" | "dbname" | "initial catalog" => cfg.database = value.to_string(),
        "user" | "username" | "user id" | "uid" => cfg.user = value.to_string(),
        "password" | "pwd" => cfg.password = value.to_string(),
        "schema" | "search_path" | "searchpath" | "currentschema" => cfg.schema = value.to_string(),
        "role" => cfg.role = value.to_string(),
        "protocol" | "parser" | "dialect" => {
            let normalized = normalize_native_protocol(value).ok_or_else(|| {
                Error::new(
                    ErrorKind::Connection,
                    "only protocol=native is supported; connect to the native parser listener/port",
                )
            })?;
            cfg.protocol = normalized.to_string();
        }
        "sslmode" | "ssl mode" | "ssl" => {
            let normalized = normalize_ssl_mode(value).ok_or_else(|| {
                Error::new(
                    ErrorKind::Connection,
                    "sslmode must be disable, require, verify-ca, or verify-full",
                )
            })?;
            cfg.sslmode = normalized.to_string();
        }
        "sslrootcert" => cfg.sslrootcert = Some(value.to_string()),
        "sslcert" => cfg.sslcert = Some(value.to_string()),
        "sslkey" => cfg.sslkey = Some(value.to_string()),
        "sslpassword" => cfg.sslpassword = Some(value.to_string()),
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
            cfg.binary_transfer = parse_bool_param(value);
        }
        "compression" => {
            let normalized = normalize_compression_mode(value).ok_or_else(|| {
                Error::new(ErrorKind::Connection, "compression must be off or zstd")
            })?;
            cfg.compression = normalized.to_string();
        }
        "fetch_size" | "fetchsize" | "default_fetch_size" => {
            if let Ok(rows) = value.parse::<u32>() {
                cfg.fetch_size = rows;
            }
        }
        "manager_auth_token" | "mcp_auth_token" => cfg.manager_auth_token = value.to_string(),
        "manager_username" | "mcp_username" => cfg.manager_username = value.to_string(),
        "manager_database" | "mcp_database" => cfg.manager_database = value.to_string(),
        "manager_connection_profile" | "mcp_connection_profile" => {
            cfg.manager_connection_profile = value.to_string()
        }
        "manager_client_intent" | "mcp_client_intent" => {
            cfg.manager_client_intent = value.to_string()
        }
        "manager_client_flags" | "mcp_client_flags" => {
            cfg.manager_client_flags = value.parse::<u16>().unwrap_or(cfg.manager_client_flags)
        }
        "manager_auth_fast_path" | "mcp_auth_fast_path" => {
            cfg.manager_auth_fast_path = parse_bool_param(value);
        }
        "metadata_expand_schema_parents"
        | "metadataexpandschemaparents"
        | "expand_schema_parents"
        | "expandschemaparents"
        | "dbeaver_expand_schema_parents"
        | "dbeaverexpandschemaparents" => {
            cfg.metadata_expand_schema_parents = parse_bool_param(value);
        }
        other => {
            cfg.extra.insert(other.to_string(), value.to_string());
        }
    }
    Ok(())
}
