"""ScratchBird native wire protocol (SBWP v1.1)."""

from __future__ import annotations

import struct
from dataclasses import dataclass
from typing import Dict, List, Optional, Tuple

PROTOCOL_MAGIC = 0x53425750  # "SBWP"
PROTOCOL_VERSION_MAJOR = 1
PROTOCOL_VERSION_MINOR = 1
PROTOCOL_VERSION = (PROTOCOL_VERSION_MAJOR << 8) | PROTOCOL_VERSION_MINOR

HEADER_SIZE = 40
MAX_MESSAGE_SIZE = 1024 * 1024 * 1024


class MessageType:
    STARTUP = 0x01
    AUTH_RESPONSE = 0x02
    QUERY = 0x03
    PARSE = 0x04
    BIND = 0x05
    DESCRIBE = 0x06
    EXECUTE = 0x07
    CLOSE = 0x08
    SYNC = 0x09
    FLUSH = 0x0A
    CANCEL = 0x0B
    COPY_DATA = 0x0D
    COPY_DONE = 0x0E
    COPY_FAIL = 0x0F

    AUTH_REQUEST = 0x40
    AUTH_OK = 0x41
    AUTH_CONTINUE = 0x42
    READY = 0x43
    ROW_DESCRIPTION = 0x44
    DATA_ROW = 0x45
    COMMAND_COMPLETE = 0x46
    EMPTY_QUERY = 0x47
    ERROR = 0x48
    NOTICE = 0x49
    PARSE_COMPLETE = 0x4A
    BIND_COMPLETE = 0x4B
    CLOSE_COMPLETE = 0x4C
    PORTAL_SUSPENDED = 0x4D
    NO_DATA = 0x4E
    PARAMETER_STATUS = 0x4F
    PARAMETER_DESCRIPTION = 0x50
    COPY_IN_RESPONSE = 0x51
    COPY_OUT_RESPONSE = 0x52
    COPY_BOTH_RESPONSE = 0x53
    NOTIFICATION = 0x54
    NEGOTIATE_VERSION = 0x56
    STREAM_READY = 0x59
    STREAM_DATA = 0x5A
    STREAM_END = 0x5B
    TXN_STATUS = 0x5C
    PONG = 0x5D


class AuthMethod:
    OK = 0
    PASSWORD = 1
    MD5 = 2
    SCRAM_SHA_256 = 3
    CERTIFICATE = 4
    GSSAPI = 5
    SSPI = 6
    LDAP = 7
    SAML = 8
    OIDC = 9
    MFA_TOTP = 10
    CLUSTER_PKI = 11


MSG_FLAG_COMPRESSED = 0x01
MSG_FLAG_CONTINUED = 0x02
MSG_FLAG_FINAL = 0x04
MSG_FLAG_URGENT = 0x08
MSG_FLAG_ENCRYPTED = 0x10
MSG_FLAG_CHECKSUM = 0x20

FEATURE_COMPRESSION = 1 << 0
FEATURE_STREAMING = 1 << 1
FEATURE_SBLR = 1 << 2
FEATURE_FEDERATION = 1 << 3
FEATURE_NOTIFICATIONS = 1 << 4
FEATURE_QUERY_PLAN = 1 << 5
FEATURE_BATCH = 1 << 6
FEATURE_PIPELINE = 1 << 7
FEATURE_BINARY_COPY = 1 << 8
FEATURE_SAVEPOINTS = 1 << 9
FEATURE_2PC = 1 << 10
FEATURE_CHECKSUMS = 1 << 11


@dataclass
class MessageHeader:
    msg_type: int
    flags: int
    length: int
    sequence: int
    attachment_id: bytes
    txn_id: int


@dataclass
class Message:
    header: MessageHeader
    payload: bytes


@dataclass
class ColumnInfo:
    name: str
    table_oid: int
    column_index: int
    type_oid: int
    type_size: int
    type_modifier: int
    format: int
    nullable: bool


@dataclass
class ColumnValue:
    data: Optional[bytes]


@dataclass
class ParamValue:
    format: int
    data: Optional[bytes]


def encode_message(header: MessageHeader, payload: bytes) -> bytes:
    if len(header.attachment_id) != 16:
        raise ValueError("attachment_id must be 16 bytes")
    out = bytearray(HEADER_SIZE + len(payload))
    struct.pack_into("<I", out, 0, PROTOCOL_MAGIC)
    out[4] = PROTOCOL_VERSION_MAJOR
    out[5] = PROTOCOL_VERSION_MINOR
    out[6] = header.msg_type
    out[7] = header.flags
    struct.pack_into("<I", out, 8, len(payload))
    struct.pack_into("<I", out, 12, header.sequence)
    out[16:32] = header.attachment_id
    struct.pack_into("<Q", out, 32, header.txn_id)
    out[HEADER_SIZE:] = payload
    return bytes(out)


def decode_header(data: bytes) -> MessageHeader:
    if len(data) != HEADER_SIZE:
        raise ValueError("invalid header length")
    magic = struct.unpack_from("<I", data, 0)[0]
    if magic != PROTOCOL_MAGIC:
        raise ValueError("invalid protocol magic")
    major = data[4]
    minor = data[5]
    if major != PROTOCOL_VERSION_MAJOR or minor != PROTOCOL_VERSION_MINOR:
        raise ValueError("unsupported protocol version")
    length = struct.unpack_from("<I", data, 8)[0]
    if length > MAX_MESSAGE_SIZE:
        raise ValueError("payload too large")
    sequence = struct.unpack_from("<I", data, 12)[0]
    attachment_id = data[16:32]
    txn_id = struct.unpack_from("<Q", data, 32)[0]
    return MessageHeader(data[6], data[7], length, sequence, attachment_id, txn_id)


def build_startup_payload(features: int, params: Dict[str, str]) -> bytes:
    param_bytes = build_param_list(params)
    out = bytearray()
    out += struct.pack("<B", PROTOCOL_VERSION_MAJOR)
    out += struct.pack("<B", PROTOCOL_VERSION_MINOR)
    out += struct.pack("<H", 0)
    out += struct.pack("<Q", features)
    out += param_bytes
    return bytes(out)


def build_param_list(params: Dict[str, str]) -> bytes:
    parts = bytearray()
    for key, value in params.items():
        parts += key.encode("utf-8") + b"\x00"
        parts += value.encode("utf-8") + b"\x00"
    parts += b"\x00"
    return bytes(parts)


def parse_auth_request(payload: bytes) -> Tuple[int, bytes]:
    if len(payload) < 4:
        raise ValueError("auth request truncated")
    method = payload[0]
    return method, payload[4:]


def parse_auth_continue(payload: bytes) -> Tuple[int, int, bytes]:
    if len(payload) < 8:
        raise ValueError("auth continue truncated")
    method = payload[0]
    stage = payload[1]
    data_len = struct.unpack_from("<I", payload, 4)[0]
    if 8 + data_len > len(payload):
        raise ValueError("auth continue truncated")
    return method, stage, payload[8 : 8 + data_len]


def parse_auth_ok(payload: bytes) -> Tuple[bytes, bytes]:
    if len(payload) < 20:
        raise ValueError("auth ok truncated")
    session_id = payload[0:16]
    info_len = struct.unpack_from("<I", payload, 16)[0]
    if 20 + info_len > len(payload):
        raise ValueError("auth ok truncated")
    return session_id, payload[20 : 20 + info_len]


def build_query_payload(sql: str, flags: int, max_rows: int, timeout_ms: int) -> bytes:
    sql_bytes = sql.encode("utf-8") + b"\x00"
    out = bytearray()
    out += struct.pack("<I", flags)
    out += struct.pack("<I", max_rows)
    out += struct.pack("<I", timeout_ms)
    out += sql_bytes
    return bytes(out)


def build_parse_payload(statement_name: str, sql: str, param_types: List[int]) -> bytes:
    name_bytes = statement_name.encode("utf-8")
    sql_bytes = sql.encode("utf-8")
    out = bytearray()
    out += struct.pack("<I", len(name_bytes)) + name_bytes
    out += struct.pack("<I", len(sql_bytes)) + sql_bytes
    out += struct.pack("<H", len(param_types))
    out += struct.pack("<H", 0)
    for oid in param_types:
        out += struct.pack("<I", oid)
    return bytes(out)


def build_bind_payload(portal_name: str, statement_name: str, params: List[ParamValue], result_formats: List[int]) -> bytes:
    portal_bytes = portal_name.encode("utf-8")
    stmt_bytes = statement_name.encode("utf-8")
    out = bytearray()
    out += struct.pack("<I", len(portal_bytes)) + portal_bytes
    out += struct.pack("<I", len(stmt_bytes)) + stmt_bytes
    out += struct.pack("<H", len(params))
    for param in params:
        out += struct.pack("<H", param.format)
    out += struct.pack("<H", len(params))
    out += struct.pack("<H", 0)
    for param in params:
        if param.data is None:
            out += struct.pack("<i", -1)
        else:
            out += struct.pack("<i", len(param.data))
            out += param.data
    out += struct.pack("<H", len(result_formats))
    for fmt in result_formats:
        out += struct.pack("<H", fmt)
    return bytes(out)


def build_execute_payload(portal_name: str, max_rows: int) -> bytes:
    portal_bytes = portal_name.encode("utf-8")
    out = bytearray()
    out += struct.pack("<I", len(portal_bytes)) + portal_bytes
    out += struct.pack("<I", max_rows)
    return bytes(out)


def build_cancel_payload(cancel_type: int, target_sequence: int) -> bytes:
    return struct.pack("<II", cancel_type, target_sequence)


def parse_ready(payload: bytes) -> Tuple[int, int, int]:
    if len(payload) < 20:
        raise ValueError("ready truncated")
    status = payload[0]
    txn_id = struct.unpack_from("<Q", payload, 4)[0]
    visibility = struct.unpack_from("<Q", payload, 12)[0]
    return status, txn_id, visibility


def parse_parameter_status(payload: bytes) -> Tuple[str, str]:
    if len(payload) < 8:
        raise ValueError("parameter status truncated")
    name_len = struct.unpack_from("<I", payload, 0)[0]
    name_start = 4
    name_end = name_start + name_len
    if name_end + 4 > len(payload):
        raise ValueError("parameter status truncated")
    value_len = struct.unpack_from("<I", payload, name_end)[0]
    value_start = name_end + 4
    value_end = value_start + value_len
    if value_end > len(payload):
        raise ValueError("parameter status truncated")
    name = payload[name_start:name_end].decode("utf-8", errors="replace")
    value = payload[value_start:value_end].decode("utf-8", errors="replace")
    return name, value


def parse_row_description(payload: bytes) -> List[ColumnInfo]:
    if len(payload) < 4:
        raise ValueError("row description truncated")
    count = struct.unpack_from("<H", payload, 0)[0]
    offset = 4
    columns: List[ColumnInfo] = []
    for _ in range(count):
        if offset + 4 > len(payload):
            raise ValueError("row description truncated")
        name_len = struct.unpack_from("<I", payload, offset)[0]
        offset += 4
        if offset + name_len > len(payload):
            raise ValueError("row description truncated")
        name = payload[offset : offset + name_len].decode("utf-8", errors="replace")
        offset += name_len
        if offset + 18 > len(payload):
            raise ValueError("row description truncated")
        table_oid = struct.unpack_from("<I", payload, offset)[0]
        offset += 4
        column_index = struct.unpack_from("<H", payload, offset)[0]
        offset += 2
        type_oid = struct.unpack_from("<I", payload, offset)[0]
        offset += 4
        type_size = struct.unpack_from("<h", payload, offset)[0]
        offset += 2
        type_modifier = struct.unpack_from("<i", payload, offset)[0]
        offset += 4
        fmt = payload[offset]
        offset += 1
        nullable = payload[offset] == 1
        offset += 1
        offset += 2
        columns.append(ColumnInfo(name, table_oid, column_index, type_oid, type_size, type_modifier, fmt, nullable))
    return columns


def parse_data_row(payload: bytes, column_count: int) -> List[ColumnValue]:
    if len(payload) < 4:
        raise ValueError("row data truncated")
    count = struct.unpack_from("<H", payload, 0)[0]
    null_bytes = struct.unpack_from("<H", payload, 2)[0]
    if count != column_count:
        raise ValueError("row data column count mismatch")
    offset = 4
    if offset + null_bytes > len(payload):
        raise ValueError("row data truncated")
    null_bitmap = payload[offset : offset + null_bytes]
    offset += null_bytes
    values: List[ColumnValue] = []
    for idx in range(count):
        byte_index = idx // 8
        bit_index = idx % 8
        is_null = byte_index < len(null_bitmap) and (null_bitmap[byte_index] & (1 << bit_index))
        if is_null:
            values.append(ColumnValue(None))
            continue
        if offset + 4 > len(payload):
            raise ValueError("row data truncated")
        length = struct.unpack_from("<i", payload, offset)[0]
        offset += 4
        if length < 0:
            values.append(ColumnValue(None))
            continue
        if offset + length > len(payload):
            raise ValueError("row data truncated")
        data = payload[offset : offset + length]
        offset += length
        values.append(ColumnValue(data))
    return values


def parse_command_complete(payload: bytes) -> Tuple[int, int, int, str]:
    if len(payload) < 20:
        raise ValueError("command complete truncated")
    command_type = payload[0]
    rows = struct.unpack_from("<Q", payload, 4)[0]
    last_id = struct.unpack_from("<Q", payload, 12)[0]
    tag_bytes = payload[20:]
    if b"\x00" in tag_bytes:
        tag_bytes = tag_bytes.split(b"\x00", 1)[0]
    tag = tag_bytes.decode("utf-8", errors="replace")
    return command_type, rows, last_id, tag


def parse_error_message(payload: bytes) -> Tuple[str, str, str, str, str]:
    offset = 0
    severity = ""
    sqlstate = ""
    message = ""
    detail = ""
    hint = ""
    while offset < len(payload):
        field = payload[offset]
        offset += 1
        if field == 0:
            break
        start = offset
        while offset < len(payload) and payload[offset] != 0:
            offset += 1
        if offset >= len(payload):
            break
        value = payload[start:offset].decode("utf-8", errors="replace")
        offset += 1
        if field == ord("S"):
            severity = value
        elif field == ord("C"):
            sqlstate = value
        elif field == ord("M"):
            message = value
        elif field == ord("D"):
            detail = value
        elif field == ord("H"):
            hint = value
    return severity, sqlstate, message, detail, hint
