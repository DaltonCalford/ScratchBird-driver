# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
from __future__ import annotations

import socket

import pytest

from scratchbird import errors
from scratchbird.connection import Connection, ConnectionConfig, connect
import scratchbird.connection as connection_mod
from scratchbird.dsn import parse_dsn


def test_parse_dsn_kv_supports_semicolon_tokens():
    params = parse_dsn("host=server;port=4000;dbname=mydb;username=me")
    assert params["host"] == "server"
    assert params["port"] == "4000"
    assert params["dbname"] == "mydb"
    assert params["username"] == "me"


def test_connect_maps_common_conn_aliases(monkeypatch):
    captured = {}

    class FakeConnection:
        def __init__(self, config):
            captured["cfg"] = config

    monkeypatch.setattr(connection_mod, "Connection", FakeConnection)
    connect(
        "host=server;port=4000;dbname=mydb;username=me;password=secret;front_door_mode=managed;"
        "protocol=scratchbird_native;connecttimeout=5;sockettimeout=7;applicationname=app;binarytransfer=off",
    )
    cfg = captured["cfg"]
    assert cfg.host == "server"
    assert cfg.port == 4000
    assert cfg.database == "mydb"
    assert cfg.user == "me"
    assert cfg.password == "secret"
    assert cfg.front_door_mode == "manager_proxy"
    assert cfg.protocol == "native"
    assert cfg.connect_timeout == 5
    assert cfg.socket_timeout == 7
    assert cfg.application_name == "app"
    assert cfg.binary_transfer is False


def test_connect_maps_metadata_expand_schema_parents_aliases(monkeypatch):
    captured = {}

    class FakeConnection:
        def __init__(self, config):
            captured["cfg"] = config

    monkeypatch.setattr(connection_mod, "Connection", FakeConnection)
    connect(
        "host=server;port=4000;dbname=mydb;username=me;"
        "metadataExpandSchemaParents=true;dbeaver_expand_schema_parents=false;"
        "metadata_expand_schema_parents=1",
    )
    cfg = captured["cfg"]
    assert cfg.metadata_expand_schema_parents is True


def test_connect_captures_auth_plugin_startup_fields(monkeypatch):
    captured = {}

    class FakeConnection:
        def __init__(self, config):
            captured["cfg"] = config

    monkeypatch.setattr(connection_mod, "Connection", FakeConnection)
    connect(
        "scratchbird://alice:secret@localhost:3092/mydb?"
        "auth_method_id=scratchbird.auth.oidc&auth_payload_json=%7B%22aud%22%3A%22sb%22%7D"
        "&auth_payload_b64=YWJj&auth_provider_profile=corp",
    )
    cfg = captured["cfg"]
    assert cfg.auth_method_id == "scratchbird.auth.oidc"
    assert cfg.auth_payload_json == '{"aud":"sb"}'
    assert cfg.auth_payload_b64 == "YWJj"
    assert cfg.auth_provider_profile == "corp"


def test_build_startup_params_includes_auth_plugin_selection():
    conn = Connection.__new__(Connection)
    conn._config = ConnectionConfig(
        user="alice",
        database="db1",
        role="analyst",
        application_name="pytest",
        auth_method_id="scratchbird.auth.oidc",
        auth_payload_json='{"aud":"sb"}',
        auth_payload_b64="YWJj",
        auth_provider_profile="corp",
    )

    params = conn._build_startup_params()
    assert params["database"] == "db1"
    assert params["user"] == "alice"
    assert params["role"] == "analyst"
    assert params["application_name"] == "pytest"
    assert params["auth_method_id"] == "scratchbird.auth.oidc"
    assert params["auth_payload_json"] == '{"aud":"sb"}'
    assert params["auth_payload_b64"] == "YWJj"
    assert params["auth_provider_profile"] == "corp"


def test_startup_and_auth_rejects_invalid_auth_plugin_namespace():
    conn = Connection.__new__(Connection)
    conn._config = ConnectionConfig(
        user="alice",
        database="db1",
        auth_method_id="invalid.namespace",
    )
    conn._parameters = {}
    conn._authed = False

    with pytest.raises(errors.InterfaceError, match="invalid auth_method_id namespace"):
        conn._startup_and_auth()


def test_connect_rejects_manager_proxy_without_token_before_socket(monkeypatch):
    conn = Connection.__new__(Connection)
    conn._config = ConnectionConfig(
        user="alice",
        database="db1",
        front_door_mode="manager_proxy",
        manager_auth_token=None,
    )

    def fail_create_connection(*_args, **_kwargs):
        raise AssertionError("socket.create_connection should not be called")

    monkeypatch.setattr(connection_mod.socket, "create_connection", fail_create_connection)

    with pytest.raises(errors.InterfaceError, match="manager_proxy mode requires manager_auth_token"):
        conn._connect()


def test_read_exact_maps_socket_timeout_to_operational_error():
    conn = Connection.__new__(Connection)

    class _TimeoutSocket:
        def recv(self, _size):
            raise socket.timeout("timed out")

    conn._socket = _TimeoutSocket()
    with pytest.raises(errors.OperationalError, match="08006"):
        conn._read_exact(8)


def test_read_exact_maps_timeout_to_query_canceled_when_cancel_pending():
    conn = Connection.__new__(Connection)

    class _TimeoutSocket:
        def __init__(self):
            self._timeout = None

        def recv(self, _size):
            raise socket.timeout("timed out")

        def gettimeout(self):
            return self._timeout

        def settimeout(self, value):
            self._timeout = value

    conn._socket = _TimeoutSocket()
    conn._cancel_requested = True
    conn._cancel_socket_timeout = None

    with pytest.raises(errors.OperationalError, match="57014"):
        conn._read_exact(8)
    assert conn._cancel_requested is False


def test_read_exact_maps_oserror_to_operational_error():
    conn = Connection.__new__(Connection)

    class _FailingSocket:
        def recv(self, _size):
            raise OSError("socket read failure")

    conn._socket = _FailingSocket()
    with pytest.raises(errors.OperationalError, match="08006"):
        conn._read_exact(8)


def test_connect_maps_timeout_to_operational_error(monkeypatch):
    conn = Connection.__new__(Connection)
    conn._config = ConnectionConfig(user="alice", database="db1")

    def fail_create_connection(*_args, **_kwargs):
        raise TimeoutError("connect timed out")

    monkeypatch.setattr(connection_mod.socket, "create_connection", fail_create_connection)

    with pytest.raises(errors.OperationalError, match="08001"):
        conn._connect()


def test_connect_maps_oserror_to_operational_error(monkeypatch):
    conn = Connection.__new__(Connection)
    conn._config = ConnectionConfig(user="alice", database="db1")

    def fail_create_connection(*_args, **_kwargs):
        raise OSError("connection refused")

    monkeypatch.setattr(connection_mod.socket, "create_connection", fail_create_connection)

    with pytest.raises(errors.OperationalError, match="08001"):
        conn._connect()
