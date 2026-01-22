use bytes::{BufMut, BytesMut};

use crate::errors::{Error, ErrorKind, Result};

pub const MAGIC: u32 = 0x42444253;
pub const VERSION: u16 = 0x0100;
pub const MAX_MESSAGE_SIZE: u32 = 16 * 1024 * 1024;

pub const MSG_CONNECT_REQUEST: u8 = 0x01;
pub const MSG_CONNECT_RESPONSE: u8 = 0x02;
pub const MSG_DISCONNECT: u8 = 0x03;
pub const MSG_AUTH_REQUEST: u8 = 0x10;
pub const MSG_AUTH_RESPONSE: u8 = 0x11;
pub const MSG_QUERY: u8 = 0x20;
pub const MSG_QUERY_RESULT: u8 = 0x21;
pub const MSG_QUERY_ERROR: u8 = 0x22;
pub const MSG_QUERY_CANCEL: u8 = 0x23;
pub const MSG_PREPARE: u8 = 0x30;
pub const MSG_PREPARE_RESPONSE: u8 = 0x31;
pub const MSG_EXECUTE: u8 = 0x32;
pub const MSG_CLOSE_STATEMENT: u8 = 0x33;
pub const MSG_DESCRIBE: u8 = 0x34;
pub const MSG_DESCRIBE_RESPONSE: u8 = 0x35;
pub const MSG_BEGIN: u8 = 0x40;
pub const MSG_COMMIT: u8 = 0x41;
pub const MSG_ROLLBACK: u8 = 0x42;
pub const MSG_ROW_DESCRIPTION: u8 = 0x50;
pub const MSG_ROW_DATA: u8 = 0x51;
pub const MSG_END_RESULTS: u8 = 0x52;
pub const MSG_COMMAND_COMPLETE: u8 = 0x53;

pub const AUTH_SCRAM_SHA256: u8 = 2;

#[derive(Debug, Clone)]
pub struct ColumnInfo {
    pub name: String,
    pub wire_type: u8,
    pub type_modifier: u32,
    pub format: u16,
}

#[derive(Debug, Clone)]
pub struct ColumnValue {
    pub data: Option<Vec<u8>>,
}

pub fn encode_message(msg_type: u8, payload: &[u8], flags: u8) -> Vec<u8> {
    let mut buf = BytesMut::with_capacity(12 + payload.len());
    buf.put_u32_le(MAGIC);
    buf.put_u16_le(VERSION);
    buf.put_u8(msg_type);
    buf.put_u8(flags);
    buf.put_u32_le(payload.len() as u32);
    buf.extend_from_slice(payload);
    buf.to_vec()
}

pub fn decode_header(data: &[u8]) -> Result<(u8, u8, u32)> {
    if data.len() != 12 {
        return Err(Error::new(ErrorKind::Connection, "invalid header length"));
    }
    let magic = u32::from_le_bytes([data[0], data[1], data[2], data[3]]);
    if magic != MAGIC {
        return Err(Error::new(ErrorKind::Connection, "invalid protocol magic"));
    }
    let length = u32::from_le_bytes([data[8], data[9], data[10], data[11]]);
    if length > MAX_MESSAGE_SIZE {
        return Err(Error::new(ErrorKind::Connection, "payload too large"));
    }
    Ok((data[6], data[7], length))
}

pub fn build_connect_request(database: &str, client_name: &str, pid: u32) -> Vec<u8> {
    let mut payload = BytesMut::with_capacity(2 + 2 + 4 + 256 + 64 + 32);
    payload.put_u16_le(VERSION);
    payload.put_u16_le(0);
    payload.put_u32_le(pid);
    payload.extend_from_slice(&write_null(database, 256));
    payload.extend_from_slice(&write_null(client_name, 64));
    payload.extend_from_slice(&write_null("1.0.0", 32));
    encode_message(MSG_CONNECT_REQUEST, &payload, 0)
}

pub fn parse_connect_response(payload: &[u8]) -> Result<(bool, [u8; 16], String, String, String)> {
    if payload.len() < 1 + 2 + 2 + 16 + 64 + 32 {
        return Err(Error::new(ErrorKind::Connection, "connect response truncated"));
    }
    let status = payload[0];
    let session_id = payload[5..21].try_into().unwrap_or([0u8; 16]);
    let server_name = read_null(&payload[21..85]);
    let server_version = read_null(&payload[85..117]);
    let mut error_msg = String::new();
    let mut offset = 117;
    if status != 0 && offset + 2 <= payload.len() {
        let msg_len = u16::from_le_bytes([payload[offset], payload[offset + 1]]) as usize;
        offset += 2;
        if offset + msg_len <= payload.len() {
            error_msg = String::from_utf8_lossy(&payload[offset..offset + msg_len]).to_string();
        }
    }
    Ok((status == 0, session_id, server_name, server_version, error_msg))
}

pub fn build_auth_request(session_id: &[u8; 16], username: &str, method: u8, payload: &[u8]) -> Vec<u8> {
    let mut buffer = BytesMut::with_capacity(16 + 64 + 1 + 2 + payload.len());
    buffer.extend_from_slice(session_id);
    buffer.extend_from_slice(&write_null(username, 64));
    buffer.put_u8(method);
    buffer.put_u16_le(payload.len() as u16);
    buffer.extend_from_slice(payload);
    encode_message(MSG_AUTH_REQUEST, &buffer, 0)
}

pub fn parse_auth_response(payload: &[u8]) -> Result<(u8, u32, String, Vec<u8>)> {
    if payload.len() < 1 + 4 + 256 {
        return Err(Error::new(ErrorKind::Auth, "auth response truncated"));
    }
    let status = payload[0];
    let user_id = u32::from_le_bytes([payload[1], payload[2], payload[3], payload[4]]);
    let error_msg = read_null(&payload[5..261]);
    let extra = payload[261..].to_vec();
    Ok((status, user_id, error_msg, extra))
}

pub fn build_query(session_id: &[u8; 16], sql: &str, flags: u8) -> Vec<u8> {
    let sql_bytes = sql.as_bytes();
    let mut payload = BytesMut::with_capacity(16 + 4 + 1 + sql_bytes.len());
    payload.extend_from_slice(session_id);
    payload.put_u32_le(sql_bytes.len() as u32);
    payload.put_u8(flags);
    payload.extend_from_slice(sql_bytes);
    encode_message(MSG_QUERY, &payload, 0)
}

pub fn parse_row_description(payload: &[u8]) -> Result<Vec<ColumnInfo>> {
    if payload.len() < 2 {
        return Err(Error::new(ErrorKind::Connection, "row description truncated"));
    }
    let mut offset = 0;
    let count = u16::from_le_bytes([payload[0], payload[1]]) as usize;
    offset += 2;
    let mut columns = Vec::with_capacity(count);
    for _ in 0..count {
        if offset + 2 > payload.len() {
            return Err(Error::new(ErrorKind::Connection, "row description truncated"));
        }
        let name_len = u16::from_le_bytes([payload[offset], payload[offset + 1]]) as usize;
        offset += 2;
        let name = String::from_utf8_lossy(&payload[offset..offset + name_len]).to_string();
        offset += name_len;
        let wire_type = payload[offset];
        offset += 1;
        let modifier = u32::from_le_bytes([
            payload[offset],
            payload[offset + 1],
            payload[offset + 2],
            payload[offset + 3],
        ]);
        offset += 4;
        let format = u16::from_le_bytes([payload[offset], payload[offset + 1]]);
        offset += 2;
        columns.push(ColumnInfo {
            name,
            wire_type,
            type_modifier: modifier,
            format,
        });
    }
    Ok(columns)
}

pub fn parse_row_data(payload: &[u8]) -> Result<Vec<ColumnValue>> {
    if payload.len() < 2 {
        return Err(Error::new(ErrorKind::Connection, "row data truncated"));
    }
    let count = u16::from_le_bytes([payload[0], payload[1]]) as usize;
    let mut offset = 2;
    let mut values = Vec::with_capacity(count);
    for _ in 0..count {
        let len = u32::from_le_bytes([
            payload[offset],
            payload[offset + 1],
            payload[offset + 2],
            payload[offset + 3],
        ]);
        offset += 4;
        if (len & 0x8000_0000) != 0 {
            values.push(ColumnValue { data: None });
            continue;
        }
        let length = len as usize;
        let data = payload[offset..offset + length].to_vec();
        offset += length;
        values.push(ColumnValue { data: Some(data) });
    }
    Ok(values)
}

pub fn parse_command_complete(payload: &[u8]) -> Result<(String, i64)> {
    if payload.len() < 64 + 8 {
        return Err(Error::new(ErrorKind::Connection, "command complete truncated"));
    }
    let tag = read_null(&payload[0..64]);
    let rows = u64::from_le_bytes(payload[64..72].try_into().unwrap_or([0u8; 8])) as i64;
    Ok((tag, rows))
}

pub fn parse_query_result(payload: &[u8]) -> Result<(u8, u32, i64)> {
    if payload.len() < 1 + 4 + 8 {
        return Err(Error::new(ErrorKind::Connection, "query result truncated"));
    }
    let status = payload[0];
    let count = u32::from_le_bytes([payload[1], payload[2], payload[3], payload[4]]);
    let rows = u64::from_le_bytes(payload[5..13].try_into().unwrap_or([0u8; 8])) as i64;
    Ok((status, count, rows))
}

pub fn parse_query_error(payload: &[u8]) -> Result<(u32, String, String, String, String)> {
    if payload.len() < 4 + 6 + 2 + 2 + 2 {
        return Err(Error::new(ErrorKind::Connection, "query error truncated"));
    }
    let mut offset = 0;
    let code = u32::from_le_bytes([payload[0], payload[1], payload[2], payload[3]]);
    offset += 4;
    let sqlstate = read_null(&payload[offset..offset + 6]);
    offset += 6;
    let msg_len = u16::from_le_bytes([payload[offset], payload[offset + 1]]) as usize;
    offset += 2;
    let detail_len = u16::from_le_bytes([payload[offset], payload[offset + 1]]) as usize;
    offset += 2;
    let hint_len = u16::from_le_bytes([payload[offset], payload[offset + 1]]) as usize;
    offset += 2;
    let message = String::from_utf8_lossy(&payload[offset..offset + msg_len]).to_string();
    offset += msg_len;
    let detail = String::from_utf8_lossy(&payload[offset..offset + detail_len]).to_string();
    offset += detail_len;
    let hint = String::from_utf8_lossy(&payload[offset..offset + hint_len]).to_string();
    Ok((code, sqlstate, message, detail, hint))
}

pub fn build_begin(session_id: &[u8; 16], isolation: u8, read_only: bool) -> Vec<u8> {
    let mut payload = BytesMut::with_capacity(16 + 2);
    payload.extend_from_slice(session_id);
    payload.put_u8(isolation);
    payload.put_u8(if read_only { 1 } else { 0 });
    encode_message(MSG_BEGIN, &payload, 0)
}

pub fn build_commit(session_id: &[u8; 16]) -> Vec<u8> {
    encode_message(MSG_COMMIT, session_id, 0)
}

pub fn build_rollback(session_id: &[u8; 16]) -> Vec<u8> {
    encode_message(MSG_ROLLBACK, session_id, 0)
}

pub fn build_disconnect(session_id: &[u8; 16]) -> Vec<u8> {
    encode_message(MSG_DISCONNECT, session_id, 0)
}

fn write_null(value: &str, length: usize) -> Vec<u8> {
    let mut bytes = value.as_bytes().to_vec();
    if bytes.len() >= length {
        bytes.truncate(length - 1);
    }
    bytes.resize(length, 0);
    bytes
}

fn read_null(data: &[u8]) -> String {
    let len = data.iter().position(|b| *b == 0).unwrap_or(data.len());
    String::from_utf8_lossy(&data[..len]).to_string()
}
