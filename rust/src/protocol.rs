// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
use std::collections::HashMap;

use crate::errors::{Error, ErrorKind, Result};

pub const MAGIC: u32 = 0x53425750;
pub const VERSION_MAJOR: u8 = 1;
pub const VERSION_MINOR: u8 = 1;
pub const HEADER_SIZE: usize = 40;
pub const MAX_MESSAGE_SIZE: u32 = 1024 * 1024 * 1024;

pub const MSG_STARTUP: u8 = 0x01;
pub const MSG_AUTH_RESPONSE: u8 = 0x02;
pub const MSG_QUERY: u8 = 0x03;
pub const MSG_PARSE: u8 = 0x04;
pub const MSG_BIND: u8 = 0x05;
pub const MSG_DESCRIBE: u8 = 0x06;
pub const MSG_EXECUTE: u8 = 0x07;
pub const MSG_CLOSE: u8 = 0x08;
pub const MSG_SYNC: u8 = 0x09;
pub const MSG_FLUSH: u8 = 0x0A;
pub const MSG_CANCEL: u8 = 0x0B;
pub const MSG_COPY_DATA: u8 = 0x0D;
pub const MSG_COPY_DONE: u8 = 0x0E;
pub const MSG_COPY_FAIL: u8 = 0x0F;

pub const MSG_AUTH_REQUEST: u8 = 0x40;
pub const MSG_AUTH_OK: u8 = 0x41;
pub const MSG_AUTH_CONTINUE: u8 = 0x42;
pub const MSG_READY: u8 = 0x43;
pub const MSG_ROW_DESCRIPTION: u8 = 0x44;
pub const MSG_DATA_ROW: u8 = 0x45;
pub const MSG_COMMAND_COMPLETE: u8 = 0x46;
pub const MSG_EMPTY_QUERY: u8 = 0x47;
pub const MSG_ERROR: u8 = 0x48;
pub const MSG_NOTICE: u8 = 0x49;
pub const MSG_PARSE_COMPLETE: u8 = 0x4A;
pub const MSG_BIND_COMPLETE: u8 = 0x4B;
pub const MSG_CLOSE_COMPLETE: u8 = 0x4C;
pub const MSG_PORTAL_SUSPENDED: u8 = 0x4D;
pub const MSG_NO_DATA: u8 = 0x4E;
pub const MSG_PARAMETER_STATUS: u8 = 0x4F;
pub const MSG_PARAMETER_DESCRIPTION: u8 = 0x50;
pub const MSG_COPY_IN_RESPONSE: u8 = 0x51;
pub const MSG_COPY_OUT_RESPONSE: u8 = 0x52;
pub const MSG_COPY_BOTH_RESPONSE: u8 = 0x53;
pub const MSG_NOTIFICATION: u8 = 0x54;
pub const MSG_NEGOTIATE_VERSION: u8 = 0x56;
pub const MSG_STREAM_READY: u8 = 0x59;
pub const MSG_STREAM_DATA: u8 = 0x5A;
pub const MSG_STREAM_END: u8 = 0x5B;
pub const MSG_TXN_STATUS: u8 = 0x5C;
pub const MSG_PONG: u8 = 0x5D;

pub const MSG_FLAG_COMPRESSED: u8 = 0x01;
pub const MSG_FLAG_CONTINUED: u8 = 0x02;
pub const MSG_FLAG_FINAL: u8 = 0x04;
pub const MSG_FLAG_URGENT: u8 = 0x08;
pub const MSG_FLAG_ENCRYPTED: u8 = 0x10;
pub const MSG_FLAG_CHECKSUM: u8 = 0x20;

pub const FEATURE_COMPRESSION: u64 = 1 << 0;
pub const FEATURE_STREAMING: u64 = 1 << 1;
pub const FEATURE_SBLR: u64 = 1 << 2;
pub const FEATURE_FEDERATION: u64 = 1 << 3;
pub const FEATURE_NOTIFICATIONS: u64 = 1 << 4;
pub const FEATURE_QUERY_PLAN: u64 = 1 << 5;
pub const FEATURE_BATCH: u64 = 1 << 6;
pub const FEATURE_PIPELINE: u64 = 1 << 7;
pub const FEATURE_BINARY_COPY: u64 = 1 << 8;
pub const FEATURE_SAVEPOINTS: u64 = 1 << 9;
pub const FEATURE_2PC: u64 = 1 << 10;
pub const FEATURE_CHECKSUMS: u64 = 1 << 11;

pub const AUTH_OK: u8 = 0;
pub const AUTH_PASSWORD: u8 = 1;
pub const AUTH_MD5: u8 = 2;
pub const AUTH_SCRAM_SHA256: u8 = 3;
pub const AUTH_CERTIFICATE: u8 = 4;
pub const AUTH_GSSAPI: u8 = 5;
pub const AUTH_SSPI: u8 = 6;
pub const AUTH_LDAP: u8 = 7;
pub const AUTH_SAML: u8 = 8;
pub const AUTH_OIDC: u8 = 9;
pub const AUTH_MFA_TOTP: u8 = 10;
pub const AUTH_CLUSTER_PKI: u8 = 11;

#[derive(Debug, Clone)]
pub struct MessageHeader {
    pub msg_type: u8,
    pub flags: u8,
    pub length: u32,
    pub sequence: u32,
    pub attachment_id: [u8; 16],
    pub txn_id: u64,
}

#[derive(Debug, Clone)]
pub struct Message {
    pub header: MessageHeader,
    pub payload: Vec<u8>,
}

#[derive(Debug, Clone)]
pub struct ColumnInfo {
    pub name: String,
    pub table_oid: u32,
    pub column_index: u16,
    pub type_oid: u32,
    pub type_size: i16,
    pub type_modifier: i32,
    pub format: u8,
    pub nullable: bool,
}

#[derive(Debug, Clone)]
pub struct ColumnValue {
    pub data: Option<Vec<u8>>,
}

#[derive(Debug, Clone)]
pub struct ParamValue {
    pub format: u16,
    pub data: Option<Vec<u8>>,
}

pub fn encode_message(header: &MessageHeader, payload: &[u8]) -> Vec<u8> {
    let mut out = vec![0u8; HEADER_SIZE + payload.len()];
    out[0..4].copy_from_slice(&MAGIC.to_le_bytes());
    out[4] = VERSION_MAJOR;
    out[5] = VERSION_MINOR;
    out[6] = header.msg_type;
    out[7] = header.flags;
    out[8..12].copy_from_slice(&(payload.len() as u32).to_le_bytes());
    out[12..16].copy_from_slice(&header.sequence.to_le_bytes());
    out[16..32].copy_from_slice(&header.attachment_id);
    out[32..40].copy_from_slice(&header.txn_id.to_le_bytes());
    out[HEADER_SIZE..].copy_from_slice(payload);
    out
}

pub fn decode_header(data: &[u8]) -> Result<MessageHeader> {
    if data.len() != HEADER_SIZE {
        return Err(Error::new(ErrorKind::Connection, "invalid header length"));
    }
    let magic = u32::from_le_bytes([data[0], data[1], data[2], data[3]]);
    if magic != MAGIC {
        return Err(Error::new(ErrorKind::Connection, "invalid protocol magic"));
    }
    if data[4] != VERSION_MAJOR || data[5] != VERSION_MINOR {
        return Err(Error::new(ErrorKind::Connection, "unsupported protocol version"));
    }
    let length = u32::from_le_bytes([data[8], data[9], data[10], data[11]]);
    if length > MAX_MESSAGE_SIZE {
        return Err(Error::new(ErrorKind::Connection, "payload too large"));
    }
    let mut attachment_id = [0u8; 16];
    attachment_id.copy_from_slice(&data[16..32]);
    let txn_id = u64::from_le_bytes(data[32..40].try_into().unwrap_or([0u8; 8]));
    Ok(MessageHeader {
        msg_type: data[6],
        flags: data[7],
        length,
        sequence: u32::from_le_bytes([data[12], data[13], data[14], data[15]]),
        attachment_id,
        txn_id,
    })
}

pub fn build_startup_payload(features: u64, params: &HashMap<String, String>) -> Vec<u8> {
    let param_bytes = build_param_list(params);
    let mut out = Vec::with_capacity(2 + 2 + 8 + param_bytes.len());
    out.push(VERSION_MAJOR);
    out.push(VERSION_MINOR);
    out.extend_from_slice(&0u16.to_le_bytes());
    out.extend_from_slice(&features.to_le_bytes());
    out.extend_from_slice(&param_bytes);
    out
}

fn build_param_list(params: &HashMap<String, String>) -> Vec<u8> {
    let mut out = Vec::new();
    for (key, value) in params.iter() {
        out.extend_from_slice(key.as_bytes());
        out.push(0);
        out.extend_from_slice(value.as_bytes());
        out.push(0);
    }
    out.push(0);
    out
}

pub fn parse_auth_request(payload: &[u8]) -> Result<(u8, Vec<u8>)> {
    if payload.len() < 4 {
        return Err(Error::new(ErrorKind::Auth, "auth request truncated"));
    }
    let method = payload[0];
    Ok((method, payload[4..].to_vec()))
}

pub fn parse_auth_continue(payload: &[u8]) -> Result<(u8, u8, Vec<u8>)> {
    if payload.len() < 8 {
        return Err(Error::new(ErrorKind::Auth, "auth continue truncated"));
    }
    let method = payload[0];
    let stage = payload[1];
    let len = u32::from_le_bytes([payload[4], payload[5], payload[6], payload[7]]) as usize;
    if 8 + len > payload.len() {
        return Err(Error::new(ErrorKind::Auth, "auth continue truncated"));
    }
    Ok((method, stage, payload[8..8 + len].to_vec()))
}

pub fn parse_auth_ok(payload: &[u8]) -> Result<([u8; 16], Vec<u8>)> {
    if payload.len() < 20 {
        return Err(Error::new(ErrorKind::Auth, "auth ok truncated"));
    }
    let mut session_id = [0u8; 16];
    session_id.copy_from_slice(&payload[0..16]);
    let len = u32::from_le_bytes([payload[16], payload[17], payload[18], payload[19]]) as usize;
    if 20 + len > payload.len() {
        return Err(Error::new(ErrorKind::Auth, "auth ok truncated"));
    }
    Ok((session_id, payload[20..20 + len].to_vec()))
}

pub fn build_query_payload(sql: &str, flags: u32, max_rows: u32, timeout_ms: u32) -> Vec<u8> {
    let mut out = Vec::with_capacity(12 + sql.len() + 1);
    out.extend_from_slice(&flags.to_le_bytes());
    out.extend_from_slice(&max_rows.to_le_bytes());
    out.extend_from_slice(&timeout_ms.to_le_bytes());
    out.extend_from_slice(sql.as_bytes());
    out.push(0);
    out
}

pub fn build_parse_payload(statement_name: &str, sql: &str, param_types: &[u32]) -> Vec<u8> {
    let name_bytes = statement_name.as_bytes();
    let sql_bytes = sql.as_bytes();
    let mut out = Vec::with_capacity(4 + name_bytes.len() + 4 + sql_bytes.len() + 2 + 2 + param_types.len() * 4);
    out.extend_from_slice(&(name_bytes.len() as u32).to_le_bytes());
    out.extend_from_slice(name_bytes);
    out.extend_from_slice(&(sql_bytes.len() as u32).to_le_bytes());
    out.extend_from_slice(sql_bytes);
    out.extend_from_slice(&(param_types.len() as u16).to_le_bytes());
    out.extend_from_slice(&0u16.to_le_bytes());
    for oid in param_types {
        out.extend_from_slice(&oid.to_le_bytes());
    }
    out
}

pub fn build_bind_payload(portal_name: &str, statement_name: &str, params: &[ParamValue], result_formats: &[u16]) -> Vec<u8> {
    let portal_bytes = portal_name.as_bytes();
    let stmt_bytes = statement_name.as_bytes();
    let param_formats: Vec<u16> = params.iter().map(|p| p.format).collect();

    let mut len = 4 + portal_bytes.len() + 4 + stmt_bytes.len();
    len += 2 + param_formats.len() * 2;
    len += 2 + 2;
    for param in params {
        len += 4;
        if let Some(ref data) = param.data {
            len += data.len();
        }
    }
    len += 2 + result_formats.len() * 2;

    let mut out = Vec::with_capacity(len);
    out.extend_from_slice(&(portal_bytes.len() as u32).to_le_bytes());
    out.extend_from_slice(portal_bytes);
    out.extend_from_slice(&(stmt_bytes.len() as u32).to_le_bytes());
    out.extend_from_slice(stmt_bytes);
    out.extend_from_slice(&(param_formats.len() as u16).to_le_bytes());
    for fmt in param_formats {
        out.extend_from_slice(&fmt.to_le_bytes());
    }
    out.extend_from_slice(&(params.len() as u16).to_le_bytes());
    out.extend_from_slice(&0u16.to_le_bytes());
    for param in params {
        match param.data {
            None => out.extend_from_slice(&(-1i32).to_le_bytes()),
            Some(ref data) => {
                out.extend_from_slice(&(data.len() as i32).to_le_bytes());
                out.extend_from_slice(data);
            }
        }
    }
    out.extend_from_slice(&(result_formats.len() as u16).to_le_bytes());
    for fmt in result_formats {
        out.extend_from_slice(&fmt.to_le_bytes());
    }
    out
}

pub fn build_execute_payload(portal_name: &str, max_rows: u32) -> Vec<u8> {
    let portal_bytes = portal_name.as_bytes();
    let mut out = Vec::with_capacity(4 + portal_bytes.len() + 4);
    out.extend_from_slice(&(portal_bytes.len() as u32).to_le_bytes());
    out.extend_from_slice(portal_bytes);
    out.extend_from_slice(&max_rows.to_le_bytes());
    out
}

pub fn build_describe_payload(describe_type: u8, name: &str) -> Vec<u8> {
    let name_bytes = name.as_bytes();
    let mut out = Vec::with_capacity(8 + name_bytes.len());
    out.push(describe_type);
    out.extend_from_slice(&[0, 0, 0]);
    out.extend_from_slice(&(name_bytes.len() as u32).to_le_bytes());
    out.extend_from_slice(name_bytes);
    out
}

pub fn build_cancel_payload(cancel_type: u32, target_sequence: u32) -> Vec<u8> {
    let mut out = Vec::with_capacity(8);
    out.extend_from_slice(&cancel_type.to_le_bytes());
    out.extend_from_slice(&target_sequence.to_le_bytes());
    out
}

pub fn parse_ready(payload: &[u8]) -> Result<(u8, u64, u64)> {
    if payload.len() < 20 {
        return Err(Error::new(ErrorKind::Connection, "ready truncated"));
    }
    let status = payload[0];
    let txn_id = u64::from_le_bytes(payload[4..12].try_into().unwrap_or([0u8; 8]));
    let visibility = u64::from_le_bytes(payload[12..20].try_into().unwrap_or([0u8; 8]));
    Ok((status, txn_id, visibility))
}

pub fn parse_parameter_status(payload: &[u8]) -> Result<(String, String)> {
    if payload.len() < 8 {
        return Err(Error::new(ErrorKind::Connection, "parameter status truncated"));
    }
    let name_len = u32::from_le_bytes([payload[0], payload[1], payload[2], payload[3]]) as usize;
    let name_start = 4;
    let name_end = name_start + name_len;
    if name_end + 4 > payload.len() {
        return Err(Error::new(ErrorKind::Connection, "parameter status truncated"));
    }
    let name = String::from_utf8_lossy(&payload[name_start..name_end]).to_string();
    let value_len = u32::from_le_bytes([
        payload[name_end],
        payload[name_end + 1],
        payload[name_end + 2],
        payload[name_end + 3],
    ]) as usize;
    let value_start = name_end + 4;
    let value_end = value_start + value_len;
    if value_end > payload.len() {
        return Err(Error::new(ErrorKind::Connection, "parameter status truncated"));
    }
    let value = String::from_utf8_lossy(&payload[value_start..value_end]).to_string();
    Ok((name, value))
}

pub fn parse_parameter_description(payload: &[u8]) -> Result<Vec<u32>> {
    if payload.len() < 4 {
        return Err(Error::new(ErrorKind::Connection, "parameter description truncated"));
    }
    let count = u16::from_le_bytes([payload[0], payload[1]]) as usize;
    let mut offset = 4;
    let mut types = Vec::with_capacity(count);
    for _ in 0..count {
        if offset + 4 > payload.len() {
            return Err(Error::new(ErrorKind::Connection, "parameter description truncated"));
        }
        types.push(u32::from_le_bytes([
            payload[offset],
            payload[offset + 1],
            payload[offset + 2],
            payload[offset + 3],
        ]));
        offset += 4;
    }
    Ok(types)
}

pub fn parse_row_description(payload: &[u8]) -> Result<Vec<ColumnInfo>> {
    if payload.len() < 4 {
        return Err(Error::new(ErrorKind::Connection, "row description truncated"));
    }
    let count = u16::from_le_bytes([payload[0], payload[1]]) as usize;
    let mut offset = 4;
    let mut columns = Vec::with_capacity(count);
    for _ in 0..count {
        if offset + 4 > payload.len() {
            return Err(Error::new(ErrorKind::Connection, "row description truncated"));
        }
        let name_len = u32::from_le_bytes([
            payload[offset],
            payload[offset + 1],
            payload[offset + 2],
            payload[offset + 3],
        ]) as usize;
        offset += 4;
        if offset + name_len > payload.len() {
            return Err(Error::new(ErrorKind::Connection, "row description truncated"));
        }
        let name = String::from_utf8_lossy(&payload[offset..offset + name_len]).to_string();
        offset += name_len;
        if offset + 18 > payload.len() {
            return Err(Error::new(ErrorKind::Connection, "row description truncated"));
        }
        let table_oid = u32::from_le_bytes([
            payload[offset],
            payload[offset + 1],
            payload[offset + 2],
            payload[offset + 3],
        ]);
        offset += 4;
        let column_index = u16::from_le_bytes([payload[offset], payload[offset + 1]]);
        offset += 2;
        let type_oid = u32::from_le_bytes([
            payload[offset],
            payload[offset + 1],
            payload[offset + 2],
            payload[offset + 3],
        ]);
        offset += 4;
        let type_size = i16::from_le_bytes([payload[offset], payload[offset + 1]]);
        offset += 2;
        let type_modifier = i32::from_le_bytes([
            payload[offset],
            payload[offset + 1],
            payload[offset + 2],
            payload[offset + 3],
        ]);
        offset += 4;
        let format = payload[offset];
        offset += 1;
        let nullable = payload[offset] == 1;
        offset += 1;
        offset += 2;
        columns.push(ColumnInfo {
            name,
            table_oid,
            column_index,
            type_oid,
            type_size,
            type_modifier,
            format,
            nullable,
        });
    }
    Ok(columns)
}

pub fn parse_data_row(payload: &[u8], column_count: usize) -> Result<Vec<ColumnValue>> {
    if payload.len() < 4 {
        return Err(Error::new(ErrorKind::Connection, "row data truncated"));
    }
    let count = u16::from_le_bytes([payload[0], payload[1]]) as usize;
    let null_bytes = u16::from_le_bytes([payload[2], payload[3]]) as usize;
    if count != column_count {
        return Err(Error::new(ErrorKind::Connection, "row data column count mismatch"));
    }
    let mut offset = 4;
    if offset + null_bytes > payload.len() {
        return Err(Error::new(ErrorKind::Connection, "row data truncated"));
    }
    let null_bitmap = &payload[offset..offset + null_bytes];
    offset += null_bytes;
    let mut values = Vec::with_capacity(count);
    for idx in 0..count {
        let byte_index = idx / 8;
        let bit_index = idx % 8;
        let is_null = byte_index < null_bitmap.len() && (null_bitmap[byte_index] & (1 << bit_index)) != 0;
        if is_null {
            values.push(ColumnValue { data: None });
            continue;
        }
        if offset + 4 > payload.len() {
            return Err(Error::new(ErrorKind::Connection, "row data truncated"));
        }
        let len = i32::from_le_bytes([
            payload[offset],
            payload[offset + 1],
            payload[offset + 2],
            payload[offset + 3],
        ]);
        offset += 4;
        if len < 0 {
            values.push(ColumnValue { data: None });
            continue;
        }
        let len = len as usize;
        if offset + len > payload.len() {
            return Err(Error::new(ErrorKind::Connection, "row data truncated"));
        }
        values.push(ColumnValue {
            data: Some(payload[offset..offset + len].to_vec()),
        });
        offset += len;
    }
    Ok(values)
}

pub fn parse_command_complete(payload: &[u8]) -> Result<(u8, u64, u64, String)> {
    if payload.len() < 20 {
        return Err(Error::new(ErrorKind::Connection, "command complete truncated"));
    }
    let command_type = payload[0];
    let rows = u64::from_le_bytes(payload[4..12].try_into().unwrap_or([0u8; 8]));
    let last_id = u64::from_le_bytes(payload[12..20].try_into().unwrap_or([0u8; 8]));
    let tag_bytes = &payload[20..];
    let null_pos = tag_bytes.iter().position(|b| *b == 0).unwrap_or(tag_bytes.len());
    let tag = String::from_utf8_lossy(&tag_bytes[..null_pos]).to_string();
    Ok((command_type, rows, last_id, tag))
}

pub fn parse_error_message(payload: &[u8]) -> Result<(String, String, String, String, String)> {
    let mut offset = 0;
    let mut severity = String::new();
    let mut sqlstate = String::new();
    let mut message = String::new();
    let mut detail = String::new();
    let mut hint = String::new();

    while offset < payload.len() {
        let field = payload[offset];
        offset += 1;
        if field == 0 {
            break;
        }
        let start = offset;
        while offset < payload.len() && payload[offset] != 0 {
            offset += 1;
        }
        if offset >= payload.len() {
            break;
        }
        let value = String::from_utf8_lossy(&payload[start..offset]).to_string();
        offset += 1;
        match field as char {
            'S' => severity = value,
            'C' => sqlstate = value,
            'M' => message = value,
            'D' => detail = value,
            'H' => hint = value,
            _ => {}
        }
    }

    Ok((severity, sqlstate, message, detail, hint))
}
