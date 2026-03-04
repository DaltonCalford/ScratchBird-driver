from __future__ import annotations

import pytest

from scratchbird import errors
from scratchbird.connection import Connection, _map_sqlstate


def _new_connection() -> Connection:
    conn = Connection.__new__(Connection)
    conn._closed = False
    return conn


def _error_payload(**fields: str) -> bytes:
    out = bytearray()
    for tag, value in fields.items():
        out += tag.encode("ascii")
        out += value.encode("utf-8")
        out += b"\x00"
    out += b"\x00"
    return bytes(out)


@pytest.mark.parametrize(
    ("sqlstate", "expected"),
    [
        ("01000", errors.Warning),
        ("0A000", errors.NotSupportedError),
        ("22P02", errors.DataError),
        ("23505", errors.IntegrityError),
        ("42601", errors.ProgrammingError),
        ("08006", errors.OperationalError),
        ("08ZZZ", errors.OperationalError),
        ("42ZZZ", errors.ProgrammingError),
        ("XX000", errors.InternalError),
        ("40001", errors.DatabaseError),
        ("99999", errors.DatabaseError),
        ("1234", errors.DatabaseError),
    ],
)
def test_map_sqlstate_returns_expected_dbapi_class(sqlstate, expected):
    assert _map_sqlstate(sqlstate) is expected


def test_raise_protocol_error_uses_sqlstate_class_and_formats_message():
    conn = _new_connection()
    payload = _error_payload(
        S="ERROR",
        C="23505",
        M="duplicate key value violates unique constraint",
        D="Key (id)=(1) already exists.",
        H="Use a new id.",
    )

    with pytest.raises(errors.IntegrityError) as exc:
        conn._raise_protocol_error(payload)

    message = str(exc.value)
    assert message.startswith("[23505] duplicate key value violates unique constraint")
    assert "DETAIL: Key (id)=(1) already exists." in message
    assert "HINT: Use a new id." in message


def test_raise_protocol_error_without_sqlstate_uses_database_error():
    conn = _new_connection()
    payload = _error_payload(M="syntax error at or near \"select\"")

    with pytest.raises(errors.DatabaseError, match='syntax error at or near "select"'):
        conn._raise_protocol_error(payload)


def test_raise_protocol_error_without_message_falls_back_to_query_failed():
    conn = _new_connection()

    with pytest.raises(errors.DatabaseError, match="query failed"):
        conn._raise_protocol_error(b"\x00")


def test_raise_protocol_error_parser_failure_falls_back_to_query_failed(monkeypatch):
    conn = _new_connection()

    def _raise(_payload):
        raise ValueError("bad payload")

    monkeypatch.setattr("scratchbird.connection.parse_error_message", _raise)

    with pytest.raises(errors.DatabaseError, match="query failed"):
        conn._raise_protocol_error(b"bad")
