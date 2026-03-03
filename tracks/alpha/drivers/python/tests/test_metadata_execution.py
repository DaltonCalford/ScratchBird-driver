# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
from __future__ import annotations

import pytest

from scratchbird import errors
from scratchbird.connection import Connection
from scratchbird.metadata import (
    CATALOGS_QUERY,
    COLUMN_PRIVILEGES_QUERY,
    FOREIGN_KEYS_QUERY,
    PRIMARY_KEYS_QUERY,
    TABLE_PRIVILEGES_QUERY,
    TYPE_INFO_QUERY,
    normalize_collection_name,
    resolve_collection_query,
)


@pytest.mark.parametrize(
    ("alias", "expected"),
    [
        ("table", "tables"),
        ("schemas", "schemas"),
        ("catalog", "catalogs"),
        ("primarykeys", "primary_keys"),
        ("foreign_keys", "foreign_keys"),
        ("tablePrivileges", "table_privileges"),
        ("column-privileges", "column_privileges"),
        ("type info", "type_info"),
    ],
)
def test_normalize_collection_name_aliases(alias: str, expected: str):
    assert normalize_collection_name(alias) == expected


@pytest.mark.parametrize(
    ("collection", "query"),
    [
        ("catalogs", CATALOGS_QUERY),
        ("primary_keys", PRIMARY_KEYS_QUERY),
        ("foreignkey", FOREIGN_KEYS_QUERY),
        ("tableprivileges", TABLE_PRIVILEGES_QUERY),
        ("column_privileges", COLUMN_PRIVILEGES_QUERY),
        ("typeinfo", TYPE_INFO_QUERY),
    ],
)
def test_resolve_collection_query_extended_families(collection: str, query: str):
    assert resolve_collection_query(collection) == query


def test_resolve_collection_query_rejects_unknown_collection():
    with pytest.raises(ValueError, match="not supported"):
        resolve_collection_query("unsupported_collection")


def test_connection_query_metadata_executes_resolved_sql():
    conn = Connection.__new__(Connection)
    conn._closed = False
    captured = {}

    class DummyCursor:
        pass

    expected_cursor = DummyCursor()

    def fake_execute(sql: str, params=None):
        captured["sql"] = sql
        captured["params"] = params
        return expected_cursor

    conn.execute = fake_execute

    actual = Connection.query_metadata(conn, "primaryKeys")
    assert actual is expected_cursor
    assert captured["sql"] == PRIMARY_KEYS_QUERY
    assert captured["params"] is None


def test_connection_get_schema_drains_cursor_rows():
    conn = Connection.__new__(Connection)
    conn._closed = False

    rows = [{"catalog_name": "sys"}, {"catalog_name": "users"}]

    class DummyCursor:
        def fetchall(self):
            return rows

    def fake_execute(sql: str, params=None):
        assert sql == CATALOGS_QUERY
        return DummyCursor()

    conn.execute = fake_execute

    actual_rows = Connection.get_schema(conn, "catalog")
    assert actual_rows == rows


def test_connection_query_metadata_maps_unsupported_collection_to_not_supported():
    conn = Connection.__new__(Connection)
    conn._closed = False
    conn.execute = lambda *_args, **_kwargs: None

    with pytest.raises(errors.NotSupportedError, match="not supported"):
        Connection.query_metadata(conn, "nope")
