from __future__ import annotations

import struct

import pytest

from scratchbird import errors
from scratchbird.connection import Connection
from scratchbird.cursor import Cursor
from scratchbird.protocol import (
    MessageType,
    TXN_FLAG_HAS_ACCESS,
    TXN_FLAG_HAS_AUTOCOMMIT,
    TXN_FLAG_HAS_DEFERRABLE,
    TXN_FLAG_HAS_ISOLATION,
    TXN_FLAG_HAS_TIMEOUT,
    TXN_FLAG_HAS_WAIT,
    build_txn_savepoint_payload,
)


def _new_connection(txn_id: int = 0) -> Connection:
    conn = Connection.__new__(Connection)
    conn._closed = False
    conn._txn_id = txn_id
    return conn


def test_begin_rejects_nested_transaction():
    conn = _new_connection(txn_id=9)
    with pytest.raises(errors.ProgrammingError, match="transaction already active"):
        conn.begin()


def test_commit_noop_without_active_transaction(monkeypatch):
    conn = _new_connection(txn_id=0)
    calls = []
    monkeypatch.setattr(conn, "_send_message", lambda *args, **kwargs: calls.append(("send", args, kwargs)))
    monkeypatch.setattr(conn, "_drain_until_ready", lambda: calls.append(("drain", (), {})))
    conn.commit()
    assert calls == []


def test_rollback_noop_without_active_transaction(monkeypatch):
    conn = _new_connection(txn_id=0)
    calls = []
    monkeypatch.setattr(conn, "_send_message", lambda *args, **kwargs: calls.append(("send", args, kwargs)))
    monkeypatch.setattr(conn, "_drain_until_ready", lambda: calls.append(("drain", (), {})))
    conn.rollback()
    assert calls == []


def test_savepoint_requires_active_transaction():
    conn = _new_connection(txn_id=0)
    with pytest.raises(errors.ProgrammingError, match="active transaction"):
        conn.savepoint("sp1")


def test_savepoint_requires_non_empty_name():
    conn = _new_connection(txn_id=7)
    with pytest.raises(errors.ProgrammingError, match="savepoint name is required"):
        conn.savepoint("   ")


def test_savepoint_normalizes_name_and_sends_payload(monkeypatch):
    conn = _new_connection(txn_id=7)
    sent = {}
    monkeypatch.setattr(
        conn,
        "_send_message",
        lambda msg_type, payload: sent.update({"msg_type": msg_type, "payload": payload}),
    )
    monkeypatch.setattr(conn, "_drain_until_ready", lambda: sent.update({"drained": True}))
    conn.savepoint("  sp1  ")
    assert sent["msg_type"] == MessageType.TXN_SAVEPOINT
    assert sent["payload"] == build_txn_savepoint_payload("sp1")
    assert sent["drained"] is True


def test_begin_sets_expected_flags(monkeypatch):
    conn = _new_connection(txn_id=0)
    sent = {}
    monkeypatch.setattr(
        conn,
        "_send_message",
        lambda msg_type, payload: sent.update({"msg_type": msg_type, "payload": payload}),
    )
    monkeypatch.setattr(conn, "_drain_until_ready", lambda: sent.update({"drained": True}))

    conn.begin(
        isolation_level=2,
        access_mode=1,
        deferrable=True,
        wait=False,
        timeout_ms=75,
        autocommit_mode=1,
    )

    assert sent["msg_type"] == MessageType.TXN_BEGIN
    flags = struct.unpack_from("<H", sent["payload"], 0)[0]
    assert flags & TXN_FLAG_HAS_ISOLATION
    assert flags & TXN_FLAG_HAS_ACCESS
    assert flags & TXN_FLAG_HAS_DEFERRABLE
    assert flags & TXN_FLAG_HAS_WAIT
    assert flags & TXN_FLAG_HAS_TIMEOUT
    assert flags & TXN_FLAG_HAS_AUTOCOMMIT
    assert sent["drained"] is True


def test_native_sql_rewrites_parameters():
    conn = _new_connection()
    assert conn.native_sql("SELECT ?::INTEGER", [42]) == "SELECT $1::INTEGER"
    assert conn.native_sql("SELECT :v::INTEGER", {"v": 7}) == "SELECT $1::INTEGER"


def test_native_sql_maps_normalization_errors():
    conn = _new_connection()
    with pytest.raises(errors.ProgrammingError, match="not enough parameters"):
        conn.native_sql("SELECT ?::INTEGER", [])


def test_execute_query_selects_simple_or_extended_path(monkeypatch):
    conn = _new_connection()
    calls = []
    monkeypatch.setattr(conn, "_begin_operation", lambda *_args, **_kwargs: None)
    monkeypatch.setattr(conn, "_end_operation", lambda *_args, **_kwargs: None)
    monkeypatch.setattr(conn, "_send_simple_query", lambda sql, max_rows=0: calls.append(("simple", sql, max_rows)))
    monkeypatch.setattr(
        conn,
        "_send_extended_query",
        lambda sql, params, max_rows=0: calls.append(("extended", sql, list(params), max_rows)),
    )

    conn._execute_query("SELECT 1")
    conn._execute_query("SELECT ?::INTEGER", [5], max_rows=10)

    assert calls == [
        ("simple", "SELECT 1", 0),
        ("extended", "SELECT $1::INTEGER", [5], 10),
    ]


def test_execute_query_maps_normalization_errors():
    conn = _new_connection()
    with pytest.raises(errors.ProgrammingError, match="not enough parameters"):
        conn._execute_query("SELECT ?::INTEGER", [])


def test_cursor_executemany_requires_seq_of_params():
    cursor = Cursor(object())
    with pytest.raises(errors.ProgrammingError, match="seq_of_params is required"):
        cursor.executemany("SELECT 1", None)
