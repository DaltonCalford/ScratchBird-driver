from __future__ import annotations

import struct

import pytest

from scratchbird import errors
from scratchbird.connection import Connection, ResultStream
from scratchbird.cursor import Cursor
from scratchbird.protocol import (
    MessageType,
    MSG_FLAG_URGENT,
    TXN_FLAG_HAS_ACCESS,
    TXN_FLAG_HAS_AUTOCOMMIT,
    TXN_FLAG_HAS_DEFERRABLE,
    TXN_FLAG_HAS_ISOLATION,
    TXN_FLAG_HAS_TIMEOUT,
    TXN_FLAG_HAS_WAIT,
    build_cancel_payload,
    build_txn_savepoint_payload,
)


def _new_connection(txn_id: int = 0) -> Connection:
    conn = Connection.__new__(Connection)
    conn._closed = False
    conn._txn_id = txn_id
    conn._autocommit = True
    conn._cursors = []
    return conn


class _Header:
    def __init__(self, msg_type: int):
        self.msg_type = msg_type


class _ResultConnection:
    def __init__(self, messages):
        self._messages = list(messages)
        self._txn_id = 0
        self.sent_messages = []

    def _recv_message(self):
        if not self._messages:
            raise AssertionError("unexpected _recv_message call")
        return self._messages.pop(0)

    def _handle_async(self, _header, _payload):
        return False

    def _raise_protocol_error(self, payload):
        raise AssertionError(f"unexpected protocol error: {payload!r}")

    def _send_message(self, msg_type, payload):
        self.sent_messages.append((msg_type, payload))


def _row_description_payload(name: str, type_oid: int = 25) -> bytes:
    name_bytes = name.encode("utf-8")
    payload = bytearray()
    payload += struct.pack("<H", 1)
    payload += b"\x00\x00"
    payload += struct.pack("<I", len(name_bytes))
    payload += name_bytes
    payload += struct.pack("<I", 0)  # table oid
    payload += struct.pack("<H", 1)  # column index
    payload += struct.pack("<I", type_oid)
    payload += struct.pack("<h", 0)  # type size
    payload += struct.pack("<i", 0)  # type modifier
    payload += struct.pack("<B", 0)  # format text
    payload += struct.pack("<B", 1)  # nullable
    payload += b"\x00\x00"
    return bytes(payload)


def _data_row_payload(value: str) -> bytes:
    value_bytes = value.encode("utf-8")
    payload = bytearray()
    payload += struct.pack("<H", 1)  # one column
    payload += struct.pack("<H", 1)  # null bitmap bytes
    payload += b"\x00"  # not null
    payload += struct.pack("<i", len(value_bytes))
    payload += value_bytes
    return bytes(payload)


class _FakeStream:
    def __init__(self, rows, rowcount: int, lastrowid, command: str | None = None):
        self._rows = list(rows)
        self.rowcount = rowcount
        self.lastrowid = lastrowid
        self.command = command
        self.completion_count = 0
        self._completed = False
        self.columns = []

    def read_row(self):
        if self._rows:
            return self._rows.pop(0)
        if not self._completed:
            self._completed = True
            self.completion_count += 1
        return None


def test_begin_rejects_nested_transaction():
    conn = _new_connection(txn_id=9)
    with pytest.raises(errors.ProgrammingError, match="transaction already active"):
        conn.begin()


def test_cancel_sends_urgent_cancel_message(monkeypatch):
    conn = _new_connection()
    sent = {}

    def _capture(msg_type, payload, flags=0, force_zero=False):
        sent["msg_type"] = msg_type
        sent["payload"] = payload
        sent["flags"] = flags
        sent["force_zero"] = force_zero

    monkeypatch.setattr(conn, "_send_message", _capture)

    conn.cancel()

    assert sent["msg_type"] == MessageType.CANCEL
    assert sent["payload"] == build_cancel_payload(0, 0)
    assert sent["flags"] == MSG_FLAG_URGENT
    assert sent["force_zero"] is False


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


def test_autocommit_true_commits_active_transaction_before_switch(monkeypatch):
    conn = _new_connection(txn_id=13)
    conn._autocommit = False
    calls = []

    def _fake_commit():
        calls.append("commit")
        conn._txn_id = 0

    monkeypatch.setattr(conn, "commit", _fake_commit)

    conn.autocommit = True

    assert calls == ["commit"]
    assert conn.autocommit is True


def test_autocommit_true_skips_commit_without_active_transaction(monkeypatch):
    conn = _new_connection(txn_id=0)
    conn._autocommit = False
    monkeypatch.setattr(conn, "commit", lambda: pytest.fail("commit should not be called"))

    conn.autocommit = True

    assert conn.autocommit is True


def test_autocommit_setter_noops_when_value_unchanged(monkeypatch):
    conn = _new_connection(txn_id=17)
    conn._autocommit = True
    monkeypatch.setattr(conn, "commit", lambda: pytest.fail("commit should not be called"))

    conn.autocommit = True

    assert conn.autocommit is True


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


def test_native_callable_sql_rewrites_escape_calls():
    conn = _new_connection()
    assert conn.native_callable_sql("{call demo.proc(?, ?)}", [1, 2]) == "call demo.proc($1, $2)"
    assert conn.native_callable_sql("{? = call demo.fn(:id)}", {"id": 7}) == "select demo.fn($1) as return_value"


def test_native_callable_sql_maps_callable_syntax_errors():
    conn = _new_connection()
    with pytest.raises(errors.ProgrammingError, match="invalid JDBC escape call syntax"):
        conn.native_callable_sql("{call ()}")


def test_connection_call_executes_normalized_callable_sql(monkeypatch):
    conn = _new_connection()
    calls = []
    stream = _FakeStream(rows=[], rowcount=0, lastrowid=None)

    def _fake_execute_query(sql, params, max_rows=0):
        calls.append((sql, list(params), max_rows))
        return stream

    monkeypatch.setattr(conn, "_execute_query", _fake_execute_query)

    cur = conn.call("{call demo.proc(?, ?)}", [11, 22])

    assert isinstance(cur, Cursor)
    assert calls == [("call demo.proc($1, $2)", [11, 22], 0)]


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


def test_result_stream_propagates_command_complete_last_id():
    command_complete_payload = struct.pack("<B3xQQ", 1, 3, 91) + b"INSERT 0 3\x00"
    ready_payload = struct.pack("<B3xQQ", 0, 77, 0)
    conn = _ResultConnection(
        [
            (_Header(MessageType.COMMAND_COMPLETE), command_complete_payload),
            (_Header(MessageType.READY), ready_payload),
        ]
    )
    stream = ResultStream(conn, page_size=0)

    assert stream.read_row() is None
    assert stream.rowcount == 3
    assert stream.lastrowid == 91
    assert stream.command == "INSERT 0 3"
    assert conn._txn_id == 77


def test_result_stream_exposes_next_result_set_boundaries():
    ready_payload = struct.pack("<B3xQQ", 0, 81, 0)
    conn = _ResultConnection(
        [
            (_Header(MessageType.ROW_DESCRIPTION), _row_description_payload("first_value")),
            (_Header(MessageType.DATA_ROW), _data_row_payload("1")),
            (_Header(MessageType.COMMAND_COMPLETE), struct.pack("<B3xQQ", 1, 1, 7) + b"SELECT 1\x00"),
            (_Header(MessageType.ROW_DESCRIPTION), _row_description_payload("second_value")),
            (_Header(MessageType.DATA_ROW), _data_row_payload("2")),
            (_Header(MessageType.COMMAND_COMPLETE), struct.pack("<B3xQQ", 1, 1, 8) + b"SELECT 1\x00"),
            (_Header(MessageType.READY), ready_payload),
        ]
    )
    stream = ResultStream(conn, page_size=0)

    assert stream.read_row() == ("1",)
    assert stream.read_row() is None
    assert stream.rowcount == 1
    assert stream.lastrowid == 7
    assert stream.command == "SELECT 1"
    assert stream.has_next_result_set() is True
    assert stream.next_result_set() is True

    assert stream.read_row() == ("2",)
    assert stream.read_row() is None
    assert stream.rowcount == 1
    assert stream.lastrowid == 8
    assert stream.command == "SELECT 1"
    assert stream.has_next_result_set() is False
    assert stream.next_result_set() is False
    assert conn._txn_id == 81


def test_cursor_nextset_advances_between_result_sets(monkeypatch):
    ready_payload = struct.pack("<B3xQQ", 0, 90, 0)
    stream_conn = _ResultConnection(
        [
            (_Header(MessageType.ROW_DESCRIPTION), _row_description_payload("first_value")),
            (_Header(MessageType.DATA_ROW), _data_row_payload("1")),
            (_Header(MessageType.COMMAND_COMPLETE), struct.pack("<B3xQQ", 1, 1, 7) + b"SELECT 1\x00"),
            (_Header(MessageType.ROW_DESCRIPTION), _row_description_payload("second_value")),
            (_Header(MessageType.DATA_ROW), _data_row_payload("2")),
            (_Header(MessageType.COMMAND_COMPLETE), struct.pack("<B3xQQ", 1, 1, 8) + b"SELECT 1\x00"),
            (_Header(MessageType.READY), ready_payload),
        ]
    )
    stream = ResultStream(stream_conn, page_size=0)

    conn = _new_connection()
    monkeypatch.setattr(conn, "_execute_query", lambda *_args, **_kwargs: stream)

    cursor = Cursor(conn)
    cursor.execute("SELECT 1; SELECT 2")

    assert cursor.fetchone() == ("1",)
    assert cursor.fetchone() is None
    assert cursor.rowcount == 1
    assert cursor.lastrowid == 7
    assert cursor.statusmessage == "SELECT 1"

    assert cursor.nextset() is True
    assert cursor.rowcount == -1
    assert cursor.lastrowid is None
    assert cursor.fetchone() == ("2",)
    assert cursor.fetchone() is None
    assert cursor.rowcount == 1
    assert cursor.lastrowid == 8
    assert cursor.statusmessage == "SELECT 1"
    assert cursor.nextset() is None


def test_cursor_execute_propagates_lastrowid_on_stream_completion(monkeypatch):
    conn = _new_connection()
    stream = _FakeStream(rows=[(1,)], rowcount=1, lastrowid=42, command="INSERT 0 1")
    monkeypatch.setattr(conn, "_execute_query", lambda *_args, **_kwargs: stream)

    cursor = Cursor(conn)
    cursor.execute("INSERT INTO t VALUES (?) RETURNING id", [1])

    assert cursor.fetchone() == (1,)
    assert cursor.lastrowid is None
    assert cursor.fetchone() is None
    assert cursor.rowcount == 1
    assert cursor.lastrowid == 42
    assert cursor.statusmessage == "INSERT 0 1"
    keys = cursor.get_generated_keys()
    assert keys.rowcount == 1
    assert keys.description[0][0] == "GENERATED_KEY"
    assert keys.fetchone() == (42,)
    assert keys.fetchone() is None


def test_cursor_execute_sets_description_before_first_fetch(monkeypatch):
    ready_payload = struct.pack("<B3xQQ", 0, 77, 0)
    stream_conn = _ResultConnection(
        [
            (_Header(MessageType.ROW_DESCRIPTION), _row_description_payload("value_col")),
            (_Header(MessageType.DATA_ROW), _data_row_payload("1")),
            (_Header(MessageType.COMMAND_COMPLETE), struct.pack("<B3xQQ", 1, 1, 0) + b"SELECT 1\x00"),
            (_Header(MessageType.READY), ready_payload),
        ]
    )
    stream = ResultStream(stream_conn, page_size=0)
    conn = _new_connection()
    monkeypatch.setattr(conn, "_execute_query", lambda *_args, **_kwargs: stream)

    cursor = Cursor(conn)
    cursor.execute("SELECT 1")

    assert cursor.description is not None
    assert cursor.description[0][0] == "value_col"
    assert cursor.fetchone() == ("1",)


def test_cursor_execute_synthesizes_description_without_row_description(monkeypatch):
    ready_payload = struct.pack("<B3xQQ", 0, 88, 0)
    stream_conn = _ResultConnection(
        [
            (_Header(MessageType.DATA_ROW), _data_row_payload("1")),
            (_Header(MessageType.COMMAND_COMPLETE), struct.pack("<B3xQQ", 1, 1, 0) + b"SELECT 1\x00"),
            (_Header(MessageType.READY), ready_payload),
        ]
    )
    stream = ResultStream(stream_conn, page_size=0)
    conn = _new_connection()
    monkeypatch.setattr(conn, "_execute_query", lambda *_args, **_kwargs: stream)

    cursor = Cursor(conn)
    cursor.execute("SELECT 1")

    assert cursor.description is not None
    assert cursor.description[0][0] == "column1"
    assert cursor.fetchone() is not None


def test_cursor_callproc_executes_callable_sql(monkeypatch):
    conn = _new_connection()
    calls = []
    stream = _FakeStream(rows=[], rowcount=0, lastrowid=None)

    def _fake_execute_query(sql, params, max_rows=0):
        calls.append((sql, list(params) if params is not None else None, max_rows))
        return stream

    monkeypatch.setattr(conn, "_execute_query", _fake_execute_query)
    cursor = Cursor(conn)

    returned = cursor.callproc("demo.proc", [5, 6])

    assert returned == [5, 6]
    assert calls == [("call demo.proc($1, $2)", [5, 6], 0)]


def test_cursor_callproc_rejects_empty_procedure_name():
    cursor = Cursor(_new_connection())
    with pytest.raises(errors.ProgrammingError, match="procname is required"):
        cursor.callproc("   ", [1])


def test_cursor_executemany_sets_final_lastrowid_and_total_rowcount(monkeypatch):
    conn = _new_connection()
    streams = [
        _FakeStream(rows=[], rowcount=1, lastrowid=10, command="INSERT 0 1"),
        _FakeStream(rows=[], rowcount=2, lastrowid=11, command="INSERT 0 2"),
    ]
    calls = []

    def _fake_execute_query(sql, params, max_rows=0):
        calls.append((sql, tuple(params), max_rows))
        return streams[len(calls) - 1]

    monkeypatch.setattr(conn, "_execute_query", _fake_execute_query)

    cursor = Cursor(conn)
    cursor.executemany("INSERT INTO t VALUES (?)", [(1,), (2,)])

    assert calls == [
        ("INSERT INTO t VALUES (?)", (1,), 0),
        ("INSERT INTO t VALUES (?)", (2,), 0),
    ]
    assert cursor.rowcount == 3
    assert cursor.lastrowid == 11
    assert cursor.statusmessage == "INSERT 0 2"
    assert cursor.get_generated_keys().fetchall() == [(10,), (11,)]


def test_connection_execute_batch_returns_summary(monkeypatch):
    conn = _new_connection()
    calls = []

    class _FakeCursor:
        def __init__(self, rowcount, lastrowid, command):
            self.rowcount = rowcount
            self.lastrowid = lastrowid
            self.statusmessage = command
            self.description = [("id", 23, None, None, None, None, True)]

        def fetchall(self):
            return []

    cursors = [
        _FakeCursor(1, 10, "INSERT 0 1"),
        _FakeCursor(2, 11, "INSERT 0 2"),
    ]

    def _fake_execute(sql, params=None):
        calls.append((sql, tuple(params) if params is not None else None))
        return cursors[len(calls) - 1]

    monkeypatch.setattr(conn, "execute", _fake_execute)

    result = conn.execute_batch("INSERT INTO t VALUES (?)", [(1,), (2,)])

    assert calls == [
        ("INSERT INTO t VALUES (?)", (1,)),
        ("INSERT INTO t VALUES (?)", (2,)),
    ]
    assert result["totalRowCount"] == 3
    assert result["items"][0]["index"] == 0
    assert result["items"][0]["rowCount"] == 1
    assert result["items"][0]["lastId"] == 10
    assert result["items"][0]["command"] == "INSERT 0 1"
    assert result["items"][1]["index"] == 1
    assert result["items"][1]["rowCount"] == 2
    assert result["items"][1]["lastId"] == 11
    assert result["items"][1]["command"] == "INSERT 0 2"


def test_connection_execute_batch_validates_inputs():
    conn = _new_connection()
    with pytest.raises(errors.ProgrammingError, match="sql is required"):
        conn.execute_batch(None, [])
    with pytest.raises(errors.ProgrammingError, match="batch_params is required"):
        conn.execute_batch("INSERT INTO t VALUES (?)", None)


def test_connection_query_batch_aliases_execute_batch(monkeypatch):
    conn = _new_connection()
    monkeypatch.setattr(conn, "execute_batch", lambda sql, params: {"sql": sql, "params": params})
    result = conn.query_batch("SELECT 1", [()])
    assert result == {"sql": "SELECT 1", "params": [()]}


def test_connection_query_multi_returns_result_set_summaries(monkeypatch):
    ready_payload = struct.pack("<B3xQQ", 0, 91, 0)
    stream_conn = _ResultConnection(
        [
            (_Header(MessageType.ROW_DESCRIPTION), _row_description_payload("first_value")),
            (_Header(MessageType.DATA_ROW), _data_row_payload("1")),
            (_Header(MessageType.COMMAND_COMPLETE), struct.pack("<B3xQQ", 1, 1, 7) + b"SELECT 1\x00"),
            (_Header(MessageType.ROW_DESCRIPTION), _row_description_payload("second_value")),
            (_Header(MessageType.DATA_ROW), _data_row_payload("2")),
            (_Header(MessageType.COMMAND_COMPLETE), struct.pack("<B3xQQ", 1, 1, 8) + b"SELECT 1\x00"),
            (_Header(MessageType.READY), ready_payload),
        ]
    )
    stream = ResultStream(stream_conn, page_size=0)
    conn = _new_connection()
    monkeypatch.setattr(conn, "_execute_query", lambda *_args, **_kwargs: stream)

    result_sets = conn.query_multi("SELECT 1; SELECT 2")

    assert len(result_sets) == 2
    assert result_sets[0]["rows"] == [("1",)]
    assert result_sets[0]["rowCount"] == 1
    assert result_sets[0]["command"] == "SELECT 1"
    assert result_sets[0]["lastId"] == 7
    assert result_sets[1]["rows"] == [("2",)]
    assert result_sets[1]["rowCount"] == 1
    assert result_sets[1]["command"] == "SELECT 1"
    assert result_sets[1]["lastId"] == 8


def test_connection_execute_multi_aliases_query_multi(monkeypatch):
    conn = _new_connection()
    monkeypatch.setattr(conn, "query_multi", lambda sql, params=None: {"sql": sql, "params": params})
    result = conn.execute_multi("SELECT 1", [1])
    assert result == {"sql": "SELECT 1", "params": [1]}


def test_generated_keys_accumulate_across_result_sets(monkeypatch):
    ready_payload = struct.pack("<B3xQQ", 0, 90, 0)
    stream_conn = _ResultConnection(
        [
            (_Header(MessageType.ROW_DESCRIPTION), _row_description_payload("first_value")),
            (_Header(MessageType.DATA_ROW), _data_row_payload("1")),
            (_Header(MessageType.COMMAND_COMPLETE), struct.pack("<B3xQQ", 1, 1, 7) + b"SELECT 1\x00"),
            (_Header(MessageType.ROW_DESCRIPTION), _row_description_payload("second_value")),
            (_Header(MessageType.DATA_ROW), _data_row_payload("2")),
            (_Header(MessageType.COMMAND_COMPLETE), struct.pack("<B3xQQ", 1, 1, 8) + b"SELECT 1\x00"),
            (_Header(MessageType.READY), ready_payload),
        ]
    )
    stream = ResultStream(stream_conn, page_size=0)

    conn = _new_connection()
    monkeypatch.setattr(conn, "_execute_query", lambda *_args, **_kwargs: stream)

    cursor = Cursor(conn)
    cursor.execute("SELECT 1; SELECT 2")
    assert cursor.fetchone() == ("1",)
    assert cursor.fetchone() is None
    assert cursor.nextset() is True
    assert cursor.fetchone() == ("2",)
    assert cursor.fetchone() is None
    assert cursor.get_generated_keys().fetchall() == [(7,), (8,)]


def test_connection_execute_with_generated_keys(monkeypatch):
    conn = _new_connection()
    stream = _FakeStream(rows=[], rowcount=1, lastrowid=55, command="INSERT 0 1")
    monkeypatch.setattr(conn, "_execute_query", lambda *_args, **_kwargs: stream)

    keys = conn.execute_with_generated_keys("INSERT INTO t VALUES (?)", [1])
    assert keys.fetchall() == [(55,)]
