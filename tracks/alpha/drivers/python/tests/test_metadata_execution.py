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
    filter_rows_by_restrictions,
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


def test_connection_get_schema_forwards_restrictions():
    conn = Connection.__new__(Connection)
    conn._closed = False
    captured = {}

    class DummyCursor:
        def fetchall(self):
            return [("users",)]

    def fake_query_metadata(collection_name="tables", restrictions=None):
        captured["collection_name"] = collection_name
        captured["restrictions"] = restrictions
        return DummyCursor()

    conn.query_metadata = fake_query_metadata

    rows = Connection.get_schema(conn, "schemas", restrictions={"schema": "users"})
    assert rows == [("users",)]
    assert captured == {"collection_name": "schemas", "restrictions": {"schema": "users"}}


def test_filter_rows_by_restrictions_filters_mapping_rows_with_aliases():
    rows = [
        {"schema_name": "sys", "table_name": "events"},
        {"schema_name": "users", "table_name": "events"},
        {"schema_name": "users", "table_name": "profiles"},
    ]

    filtered = filter_rows_by_restrictions(
        rows,
        {"schema": "users", "table": "events"},
        collection_name="tables",
    )
    assert filtered == [{"schema_name": "users", "table_name": "events"}]


def test_connection_query_metadata_with_restrictions_filters_tuple_rows_from_description():
    conn = Connection.__new__(Connection)
    conn._closed = False

    rows = [("sys", "events"), ("users", "events"), ("users", "profiles")]
    description = [
        ("schema_name", None, None, None, None, None, True),
        ("table_name", None, None, None, None, None, True),
    ]

    class DummyCursor:
        def __init__(self):
            self.description = description
            self.statusmessage = "SELECT"
            self.lastrowid = None

        def fetchall(self):
            return list(rows)

    def fake_execute(sql: str, params=None):
        assert sql == PRIMARY_KEYS_QUERY
        assert params is None
        return DummyCursor()

    conn.execute = fake_execute

    actual = Connection.query_metadata(conn, "primary_keys", restrictions={"schema": "users"})
    assert actual.description == description
    assert actual.fetchall() == [("users", "events"), ("users", "profiles")]


def test_connection_query_metadata_with_restrictions_supports_null_and_ignores_unknown_keys():
    conn = Connection.__new__(Connection)
    conn._closed = False

    rows = [{"table_name": "events", "owner_id": None}, {"table_name": "events", "owner_id": 7}]

    class DummyCursor:
        description = [("table_name", None, None, None, None, None, True), ("owner_id", None, None, None, None, None, True)]
        statusmessage = "SELECT"
        lastrowid = None

        def fetchall(self):
            return list(rows)

    conn.execute = lambda *_args, **_kwargs: DummyCursor()

    actual = Connection.query_metadata(
        conn,
        "tables",
        restrictions={"owner_id": "null", "missing_filter": "ignored"},
    )
    assert actual.fetchall() == [{"table_name": "events", "owner_id": None}]


def test_connection_query_metadata_with_restrictions_rejects_non_mapping():
    conn = Connection.__new__(Connection)
    conn._closed = False

    class DummyCursor:
        description = []
        statusmessage = "SELECT"
        lastrowid = None

        def fetchall(self):
            return []

    conn.execute = lambda *_args, **_kwargs: DummyCursor()

    with pytest.raises(errors.ProgrammingError, match="mapping"):
        Connection.query_metadata(conn, "tables", restrictions=["not", "a", "mapping"])
