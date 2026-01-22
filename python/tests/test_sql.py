from __future__ import annotations

from scratchbird.sql import normalize_query


def test_normalize_positional():
    sql = "SELECT ?"
    rewritten, params = normalize_query(sql, (1,))
    assert rewritten == "SELECT $1"
    assert params == [1]


def test_normalize_named():
    sql = "SELECT :id, @name"
    rewritten, params = normalize_query(sql, {"id": 1, "name": "Ada"})
    assert rewritten == "SELECT $1, $2"
    assert params == [1, "Ada"]
