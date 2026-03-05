from __future__ import annotations

import pathlib
import struct
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / "src"))

import scratchbird


def _require(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


class TxnHarness:
    def __init__(self, txn_id: int):
        self._txn_id = txn_id
        self.sent = []
        self.drained = 0

    def _send_message(self, msg_type: int, payload: bytes, flags: int = 0, force_zero: bool = False):
        self.sent.append((msg_type, payload, flags, force_zero))

    def _drain_until_ready(self):
        self.drained += 1


class QueryHarness:
    def __init__(self):
        self.calls = []
        self.result = scratchbird.ScratchBirdResult([[1]], [], 1)

    def _begin_operation(self, name: str, sql: str):
        self.calls.append(("begin", name, sql))
        return None

    def _end_operation(self, span, success: bool):
        self.calls.append(("end", success))

    def _extended_query(self, sql: str, params):
        self.calls.append(("extended", sql, list(params)))
        return self.result

    def _send_message(self, msg_type: int, payload: bytes, flags: int = 0, force_zero: bool = False):
        self.calls.append(("send", msg_type))

    def _read_resultset(self):
        self.calls.append(("read",))
        return self.result


def test_begin_maps_kwargs_to_payload_flags() -> None:
    conn = TxnHarness(0)
    scratchbird.ScratchBirdConnection.begin(
        conn,
        isolation_level=2,
        access_mode=1,
        deferrable=True,
        wait=False,
        timeout_ms=75,
        autocommit_mode=1,
    )

    _require(len(conn.sent) == 1, "begin should send exactly one message")
    msg_type, payload, _, _ = conn.sent[0]
    _require(msg_type == scratchbird.MessageType.TXN_BEGIN, "begin should send TXN_BEGIN")

    flags, conflict, autocommit_mode, isolation, access_mode, deferrable, wait_mode, timeout_ms = struct.unpack(
        "<HBBBBBBI", payload
    )
    _require((flags & scratchbird.TXN_FLAG_HAS_ISOLATION) != 0, "missing isolation flag")
    _require((flags & scratchbird.TXN_FLAG_HAS_ACCESS) != 0, "missing access flag")
    _require((flags & scratchbird.TXN_FLAG_HAS_DEFERRABLE) != 0, "missing deferrable flag")
    _require((flags & scratchbird.TXN_FLAG_HAS_WAIT) != 0, "missing wait flag")
    _require((flags & scratchbird.TXN_FLAG_HAS_TIMEOUT) != 0, "missing timeout flag")
    _require((flags & scratchbird.TXN_FLAG_HAS_AUTOCOMMIT) != 0, "missing autocommit flag")
    _require(conflict == 0, "unexpected conflict_action")
    _require(autocommit_mode == 1, "unexpected autocommit_mode")
    _require(isolation == 2, "unexpected isolation_level")
    _require(access_mode == 1, "unexpected access_mode")
    _require(deferrable == 1, "unexpected deferrable value")
    _require(wait_mode == 0, "unexpected wait_mode")
    _require(timeout_ms == 75, "unexpected timeout_ms")
    _require(conn.drained == 1, "begin should drain once")


def test_begin_rejects_nested_transaction() -> None:
    conn = TxnHarness(42)
    try:
        scratchbird.ScratchBirdConnection.begin(conn)
        raise RuntimeError("expected nested transaction begin rejection")
    except scratchbird.ScratchBirdError as exc:
        _require("transaction already active" in str(exc), "nested begin should raise clear message")
        _require(exc.sqlstate == "25001", "nested begin should map to 25001")
    _require(len(conn.sent) == 0, "nested begin should not send wire messages")
    _require(conn.drained == 0, "nested begin should not drain")


def test_commit_and_rollback_noop_when_no_active_txn() -> None:
    conn = TxnHarness(0)
    scratchbird.ScratchBirdConnection.commit(conn)
    scratchbird.ScratchBirdConnection.rollback(conn)
    _require(len(conn.sent) == 0, "inactive txn should not send commit/rollback")
    _require(conn.drained == 0, "inactive txn should not drain")


def test_commit_and_rollback_send_when_active_txn() -> None:
    conn = TxnHarness(42)
    scratchbird.ScratchBirdConnection.commit(conn)
    scratchbird.ScratchBirdConnection.rollback(conn)
    _require(len(conn.sent) == 2, "active txn should send commit and rollback")
    _require(conn.sent[0][0] == scratchbird.MessageType.TXN_COMMIT, "commit should send TXN_COMMIT")
    _require(conn.sent[1][0] == scratchbird.MessageType.TXN_ROLLBACK, "rollback should send TXN_ROLLBACK")
    _require(conn.drained == 2, "active txn should drain for commit/rollback")


def test_query_none_params_uses_simple_path() -> None:
    conn = QueryHarness()
    result = scratchbird.ScratchBirdConnection.query(conn, "SELECT 1", None)
    _require(result is conn.result, "query should return harness result")
    _require(("extended", "SELECT 1", []) not in conn.calls, "None params should not use extended path")
    _require(("send", scratchbird.MessageType.QUERY) in conn.calls, "simple query should send QUERY")
    _require(("read",) in conn.calls, "simple query should read resultset")


def test_query_empty_params_uses_extended_path() -> None:
    conn = QueryHarness()
    result = scratchbird.ScratchBirdConnection.query(conn, "SELECT 1", [])
    _require(result is conn.result, "query should return harness result")
    _require(("extended", "SELECT 1", []) in conn.calls, "empty params should use extended path")
    _require(("send", scratchbird.MessageType.QUERY) not in conn.calls, "extended path should not send simple QUERY")
    _require(("read",) not in conn.calls, "extended path should not call simple _read_resultset directly")


def main() -> None:
    test_begin_maps_kwargs_to_payload_flags()
    test_begin_rejects_nested_transaction()
    test_commit_and_rollback_noop_when_no_active_txn()
    test_commit_and_rollback_send_when_active_txn()
    test_query_none_params_uses_simple_path()
    test_query_empty_params_uses_extended_path()
    print("Mojo TXN/EXEC parity tests OK")


if __name__ == "__main__":
    main()
