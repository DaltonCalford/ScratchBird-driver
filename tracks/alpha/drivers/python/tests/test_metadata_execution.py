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


def test_connection_schemas_wrapper_forwards_catalog_restriction():
    conn = Connection.__new__(Connection)
    conn._closed = False
    captured = {}

    def fake_get_schema(collection_name="tables", restrictions=None):
        captured["collection_name"] = collection_name
        captured["restrictions"] = restrictions
        return [("users",)]

    conn.get_schema = fake_get_schema

    rows = Connection.schemas(conn, catalog="main")
    assert rows == [("users",)]
    assert captured == {"collection_name": "schemas", "restrictions": {"catalog": "main"}}


def test_connection_tables_wrapper_forwards_restrictions():
    conn = Connection.__new__(Connection)
    conn._closed = False
    captured = {}

    def fake_get_schema(collection_name="tables", restrictions=None):
        captured["collection_name"] = collection_name
        captured["restrictions"] = restrictions
        return [("events",)]

    conn.get_schema = fake_get_schema

    rows = Connection.tables(conn, schema="users", table="events", table_type="BASE TABLE")
    assert rows == [("events",)]
    assert captured == {
        "collection_name": "tables",
        "restrictions": {"schema": "users", "table": "events", "type": "BASE TABLE"},
    }


def test_connection_columns_wrapper_forwards_restrictions():
    conn = Connection.__new__(Connection)
    conn._closed = False
    captured = {}

    def fake_get_schema(collection_name="tables", restrictions=None):
        captured["collection_name"] = collection_name
        captured["restrictions"] = restrictions
        return [("column",)]

    conn.get_schema = fake_get_schema

    rows = Connection.columns(conn, schema="users", table="events", column="event_id", column_type="INTEGER")
    assert rows == [("column",)]
    assert captured == {
        "collection_name": "columns",
        "restrictions": {"schema": "users", "table": "events", "column": "event_id", "type": "INTEGER"},
    }


def test_connection_indexes_wrapper_handles_missing_restrictions():
    conn = Connection.__new__(Connection)
    conn._closed = False
    captured = {}

    def fake_get_schema(collection_name="tables", restrictions=None):
        captured["collection_name"] = collection_name
        captured["restrictions"] = restrictions
        return [("idx",)]

    conn.get_schema = fake_get_schema

    rows = Connection.indexes(conn)
    assert rows == [("idx",)]
    assert captured == {"collection_name": "indexes", "restrictions": None}


@pytest.mark.parametrize(
    ("method_name", "kwargs", "expected_collection", "expected_restrictions"),
    [
        (
            "index_columns",
            {"schema": "users", "table": "events", "index": "idx_events", "column": "event_id"},
            "index_columns",
            {"schema": "users", "table": "events", "index": "idx_events", "column": "event_id"},
        ),
        (
            "constraints",
            {"schema": "users", "table": "events", "constraint": "events_pk"},
            "constraints",
            {"schema": "users", "table": "events", "constraint": "events_pk"},
        ),
        ("catalogs", {}, "catalogs", None),
        ("catalogs", {"catalog": "main"}, "catalogs", {"catalog": "main"}),
        (
            "primary_keys",
            {"catalog": "main", "schema": "users", "table": "events", "constraint": "events_pk"},
            "primary_keys",
            {"catalog": "main", "schema": "users", "table": "events", "constraint": "events_pk"},
        ),
        (
            "foreign_keys",
            {"schema": "users", "table": "events"},
            "foreign_keys",
            {"schema": "users", "table": "events"},
        ),
        (
            "procedures",
            {"schema": "users", "procedure": "upsert_event"},
            "procedures",
            {"schema": "users", "procedure": "upsert_event"},
        ),
        (
            "functions",
            {"catalog": "main", "schema": "users", "function": "event_count"},
            "functions",
            {"catalog": "main", "schema": "users", "function": "event_count"},
        ),
        (
            "routines",
            {"schema": "users", "routine": "event_count"},
            "routines",
            {"schema": "users", "routine": "event_count"},
        ),
        (
            "table_privileges",
            {"schema": "users", "table": "events"},
            "table_privileges",
            {"schema": "users", "table": "events"},
        ),
        (
            "column_privileges",
            {"schema": "users", "table": "events", "column": "event_id"},
            "column_privileges",
            {"schema": "users", "table": "events", "column": "event_id"},
        ),
        ("type_info", {}, "type_info", None),
        ("type_info", {"type_name": "INTEGER"}, "type_info", {"type": "INTEGER"}),
    ],
)
def test_connection_metadata_wrappers_forward_expected_restrictions(
    method_name: str,
    kwargs: dict,
    expected_collection: str,
    expected_restrictions: dict | None,
):
    conn = Connection.__new__(Connection)
    conn._closed = False
    captured = {}

    def fake_get_schema(collection_name="tables", restrictions=None):
        captured["collection_name"] = collection_name
        captured["restrictions"] = restrictions
        return [("ok",)]

    conn.get_schema = fake_get_schema

    rows = getattr(Connection, method_name)(conn, **kwargs)
    assert rows == [("ok",)]
    assert captured == {"collection_name": expected_collection, "restrictions": expected_restrictions}


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
