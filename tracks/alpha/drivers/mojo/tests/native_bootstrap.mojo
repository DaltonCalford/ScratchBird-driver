# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

import scratchbird_native
from collections import List


fn _require(condition: Bool, message: String) raises:
    if not condition:
        raise Error(message)


fn _assert_connect_guard(dsn: String, expected_sqlstate: String, expected_fragment: String) raises:
    var cfg = scratchbird_native.ScratchBirdConfig(dsn)
    try:
        _ = scratchbird_native.connect(cfg)
        raise Error("expected connect guard to reject DSN")
    except e:
        var message = String(e)
        var sqlstate = scratchbird_native.extract_sqlstate(message)
        _require(
            sqlstate == expected_sqlstate,
            "expected sqlstate '" + expected_sqlstate + "', got '" + sqlstate + "'",
        )
        _require(
            expected_fragment in message,
            "expected guard message containing '" + expected_fragment + "', got '" + message + "'",
        )


fn _assert_metadata_guard(collection_name: String, expected_sqlstate: String, expected_fragment: String) raises:
    try:
        _ = scratchbird_native.normalize_metadata_collection_name(collection_name)
        raise Error("expected metadata guard to reject collection")
    except e:
        var message = String(e)
        var sqlstate = scratchbird_native.extract_sqlstate(message)
        _require(
            sqlstate == expected_sqlstate,
            "expected metadata sqlstate '" + expected_sqlstate + "', got '" + sqlstate + "'",
        )
        _require(
            expected_fragment in message,
            "expected metadata guard containing '" + expected_fragment + "', got '" + message + "'",
        )


fn _assert_metadata_restriction_guard(
    collection_name: String,
    restriction_key: String,
    expected_sqlstate: String,
    expected_fragment: String,
) raises:
    try:
        _ = scratchbird_native.resolve_metadata_collection_query_restricted(
            collection_name,
            restriction_key,
            "x",
        )
        raise Error("expected metadata restriction guard to reject restriction")
    except e:
        var message = String(e)
        var sqlstate = scratchbird_native.extract_sqlstate(message)
        _require(
            sqlstate == expected_sqlstate,
            "expected metadata restriction sqlstate '" + expected_sqlstate + "', got '" + sqlstate + "'",
        )
        _require(
            expected_fragment in message,
            "expected metadata restriction guard containing '" + expected_fragment + "', got '" + message + "'",
        )


fn _assert_metadata_restriction_count_guard(collection_name: String) raises:
    var keys = List[String]()
    keys.append("schema")
    var values = List[String]()
    try:
        _ = scratchbird_native.resolve_metadata_collection_query_restricted_multi(
            collection_name,
            keys,
            values,
        )
        raise Error("expected metadata restriction count guard to reject mismatch")
    except e:
        var message = String(e)
        var sqlstate = scratchbird_native.extract_sqlstate(message)
        _require(
            sqlstate == "07001",
            "expected metadata restriction count guard sqlstate '07001', got '" + sqlstate + "'",
        )


fn main() raises:
    var cfg = scratchbird_native.ScratchBirdConfig(
        "scratchbird://user:pass@localhost:3092/testdb?sslmode=require&binary_transfer=true"
    )
    _require(cfg.user == "user", "user parse mismatch")
    _require(cfg.password == "pass", "password parse mismatch")
    _require(cfg.host == "localhost", "host parse mismatch")
    _require(cfg.port == 3092, "port parse mismatch")
    _require(cfg.database == "testdb", "database parse mismatch")
    _require(cfg.connect_timeout_s == 30, "connect timeout default mismatch")
    _require(cfg.socket_timeout_s == 0, "socket timeout default mismatch")
    _require(cfg.login_timeout_s == 30, "login timeout default mismatch")
    var cfg_default_port = scratchbird_native.ScratchBirdConfig(
        "scratchbird://user:pass@localhost/testdb?sslmode=require&binary_transfer=true"
    )
    _require(cfg_default_port.port == 3092, "default port parse mismatch")
    var cfg_ipv6 = scratchbird_native.ScratchBirdConfig(
        "scratchbird://user:pass@[::1]:3092/testdb?sslmode=require"
    )
    _require(cfg_ipv6.host == "::1", "ipv6 host parse mismatch")
    _require(cfg_ipv6.port == 3092, "ipv6 port parse mismatch")
    var cfg_endpoint_override = scratchbird_native.ScratchBirdConfig(
        "scratchbird://user:pass@localhost:3092/testdb?sslmode=require&host=proxy.local&port=4100"
    )
    _require(cfg_endpoint_override.host == "proxy.local", "query host override parse mismatch")
    _require(cfg_endpoint_override.port == 4100, "query port override parse mismatch")
    var cfg_timeout_override = scratchbird_native.ScratchBirdConfig(
        "scratchbird://user:pass@localhost:3092/testdb?sslmode=require&connecttimeout=11&socket_timeout=22&logintimeout=33"
    )
    _require(cfg_timeout_override.connect_timeout_s == 11, "connect timeout override mismatch")
    _require(cfg_timeout_override.socket_timeout_s == 22, "socket timeout override mismatch")
    _require(cfg_timeout_override.login_timeout_s == 33, "login timeout override mismatch")
    var cfg_mode_precedence = scratchbird_native.ScratchBirdConfig(
        "scratchbird://user:pass@localhost:3092/testdb?sslmode=require&front_door_mode=direct&connection_mode=manager_proxy&ingress_mode=managed"
    )
    _require(cfg_mode_precedence.front_door_mode == "direct", "front_door_mode precedence mismatch")
    var cfg_connection_mode_alias = scratchbird_native.ScratchBirdConfig(
        "scratchbird://user:pass@localhost:3092/testdb?sslmode=require&connection_mode=manager-proxy"
    )
    _require(cfg_connection_mode_alias.front_door_mode == "manager_proxy", "connection_mode alias normalization mismatch")
    var cfg_ingress_mode_alias = scratchbird_native.ScratchBirdConfig(
        "scratchbird://user:pass@localhost:3092/testdb?sslmode=require&ingress_mode=managerproxy"
    )
    _require(cfg_ingress_mode_alias.front_door_mode == "manager_proxy", "ingress_mode alias normalization mismatch")
    var cfg_password_colon = scratchbird_native.ScratchBirdConfig(
        "scratchbird://user:pa:ss@localhost:3092/testdb?sslmode=require"
    )
    _require(cfg_password_colon.password == "pa:ss", "password-with-colon parse mismatch")
    var cfg_credential_override = scratchbird_native.ScratchBirdConfig(
        "scratchbird://user:pass@localhost:3092/testdb?sslmode=require&user=api_user&password=api_pass"
    )
    _require(cfg_credential_override.user == "api_user", "query user override mismatch")
    _require(cfg_credential_override.password == "api_pass", "query password override mismatch")
    var cfg_credential_override_hostonly = scratchbird_native.ScratchBirdConfig(
        "scratchbird://localhost:3092/testdb?sslmode=require&user=host_user&password=host_pass"
    )
    _require(cfg_credential_override_hostonly.user == "host_user", "host-only user override mismatch")
    _require(cfg_credential_override_hostonly.password == "host_pass", "host-only password override mismatch")

    var conn = scratchbird_native.connect(cfg)
    _require(conn.connection_id == "user@localhost:3092/testdb", "connection_id format mismatch")
    _require(conn.ping(), "ping should return true")
    _require(conn.query("SELECT 1") == 1, "SELECT 1 should return 1")
    _require(conn.query("SELECT * FROM type_coverage") == 1, "type_coverage stub should return success")
    _require(conn.query("SELECT id FROM basic_table ORDER BY id") == 6, "basic_table query rowcount mismatch")
    conn.commit()
    conn.rollback()
    conn.begin()
    try:
        conn.begin()
        raise Error("expected nested transaction begin to fail")
    except e:
        _require("25001" in String(e), "nested transaction should report 25001")
    conn.rollback()
    conn.begin()
    var auto_savepoint = conn.set_savepoint()
    _require(auto_savepoint == "sp_1", "generated savepoint name mismatch")
    _require(conn.set_savepoint("named_sp") == "named_sp", "named savepoint mismatch")
    _ = conn.set_savepoint("tail_sp")
    conn.rollback_to_savepoint("named_sp")
    try:
        conn.release_savepoint("tail_sp")
        raise Error("expected rolled-back savepoint release to fail")
    except e:
        _require("3B001" in String(e), "missing savepoint should report 3B001")
    conn.release_savepoint("named_sp")
    conn.commit()
    try:
        _ = conn.set_savepoint()
        raise Error("expected inactive savepoint guard")
    except e:
        _require("25000" in String(e), "inactive savepoint should report 25000")
    conn.commit()
    var p1 = List[String]()
    p1.append("42")
    _require(conn.query_with_params("SELECT $1::INTEGER", p1) == 42, "single-parameter query mismatch")
    var p2 = List[String]()
    p2.append("5")
    p2.append("7")
    _require(conn.query_with_params("SELECT $1::INTEGER, $2::INTEGER", p2) == 12, "two-parameter query mismatch")
    var stmt = conn.prepare("SELECT $1::INTEGER, $2::INTEGER")
    _require(stmt.execute(p2) == 12, "prepared execute mismatch")
    try:
        _ = conn.query_with_params("SELECT $1::INTEGER, $2::INTEGER", p1)
        raise Error("expected parameter mismatch")
    except e:
        _require("07001" in String(e), "parameter mismatch should include 07001")
    try:
        _ = stmt.execute(p1)
        raise Error("expected prepared mismatch")
    except e:
        _require("07001" in String(e), "prepared mismatch should include 07001")
    _require(
        conn.query_metadata("table") == scratchbird_native.METADATA_TABLES_QUERY,
        "metadata table alias mismatch",
    )
    _require(
        conn.query_metadata("schemas") == scratchbird_native.METADATA_SCHEMAS_QUERY,
        "metadata schemas query mismatch",
    )
    _require(
        conn.query_metadata("index_columns") == scratchbird_native.METADATA_INDEX_COLUMNS_QUERY,
        "metadata index_columns query mismatch",
    )
    _require(
        conn.query_metadata("typeinfo") == scratchbird_native.METADATA_TYPE_INFO_QUERY,
        "metadata typeinfo alias mismatch",
    )
    _require(
        conn.query_metadata("routines") == scratchbird_native.METADATA_ROUTINES_QUERY,
        "metadata routines query mismatch",
    )
    _require(
        conn.query_metadata_rows("table") == 1,
        "metadata table execution rowcount mismatch",
    )
    _require(
        conn.query_metadata_rows("typeinfo") == 1,
        "metadata typeinfo execution rowcount mismatch",
    )
    var restricted_tables = conn.query_metadata_restricted("table", "name", "orders")
    _require(
        restricted_tables
        == "SELECT table_id, schema_id, table_name, table_type, owner_id FROM sys.tables WHERE is_valid = 1 AND table_name = 'orders' ORDER BY table_name",
        "restricted metadata table query mismatch",
    )
    _require(
        conn.query_metadata_rows_restricted("table", "name", "orders") == 1,
        "restricted metadata table execution rowcount mismatch",
    )
    var multi_keys = List[String]()
    multi_keys.append("schema")
    multi_keys.append("table")
    var multi_values = List[String]()
    multi_values.append("public")
    multi_values.append("orders")
    var multi_tables = conn.query_metadata_restricted_multi("tables", multi_keys, multi_values)
    _require(
        "schema_id IN (SELECT schema_id FROM sys.schemas WHERE schema_name = 'public')" in multi_tables,
        "multi restriction query should include schema predicate",
    )
    _require(
        "table_name = 'orders'" in multi_tables,
        "multi restriction query should include table predicate",
    )
    _require(
        conn.query_metadata_rows_restricted_multi("tables", multi_keys, multi_values) == 1,
        "multi restriction rowcount mismatch",
    )
    var wildcard_tables = conn.query_metadata_restricted("tables", "table", "ord%")
    _require(
        "table_name LIKE 'ord%'" in wildcard_tables,
        "table wildcard restriction should use LIKE predicate",
    )
    var escaped_wildcard_tables = conn.query_metadata_restricted("tables", "table", "ord\\%")
    _require(
        "table_name LIKE 'ord\\%' ESCAPE '\\'" in escaped_wildcard_tables,
        "escaped table wildcard restriction should preserve ESCAPE semantics",
    )
    _require(
        conn.query_metadata_rows_restricted("tables", "table", "ord%") == 1,
        "table wildcard restriction rowcount mismatch",
    )
    var restricted_schema = conn.query_metadata_restricted("schema", "schema", "acme'schema")
    _require(
        "schema_name = 'acme''schema'" in restricted_schema,
        "restricted metadata schema query should escape SQL literals",
    )
    var null_restricted_schema = conn.query_metadata_restricted("schema", "schema", "null")
    _require(
        "schema_name IS NULL" in null_restricted_schema,
        "null schema restriction should emit IS NULL predicate",
    )
    var restricted_columns_schema = conn.query_metadata_restricted("columns", "schema", "public")
    _require(
        "table_id IN (SELECT t.table_id FROM sys.tables t JOIN sys.schemas s ON s.schema_id = t.schema_id WHERE s.schema_name = 'public')"
        in restricted_columns_schema,
        "columns schema restriction should map through table-schema subquery",
    )
    var wildcard_columns_schema = conn.query_metadata_restricted("columns", "schema", "pub%")
    _require(
        "s.schema_name LIKE 'pub%'" in wildcard_columns_schema,
        "columns schema wildcard restriction should use LIKE predicate",
    )
    var escaped_wildcard_columns_schema = conn.query_metadata_restricted("columns", "schema", "pub\\_%")
    _require(
        "s.schema_name LIKE 'pub\\_%' ESCAPE '\\'" in escaped_wildcard_columns_schema,
        "columns escaped wildcard restriction should preserve ESCAPE semantics",
    )
    _require(
        conn.query_metadata_rows_restricted("columns", "schema", "public") == 1,
        "columns schema restriction rowcount mismatch",
    )
    var restricted_indexes_table = conn.query_metadata_restricted("indexes", "table", "orders")
    _require(
        "table_id IN (SELECT table_id FROM sys.tables WHERE table_name = 'orders')" in restricted_indexes_table,
        "indexes table restriction should map through table-name subquery",
    )
    var restricted_index_columns_table = conn.query_metadata_restricted("index_columns", "table", "orders")
    _require(
        "index_id IN (SELECT i.index_id FROM sys.indexes i JOIN sys.tables t ON t.table_id = i.table_id WHERE t.table_name = 'orders')"
        in restricted_index_columns_table,
        "index_columns table restriction should map through index-table subquery",
    )
    var restricted_tables_catalog = conn.query_metadata_restricted("tables", "catalog", "public")
    _require(
        "schema_id IN (SELECT schema_id FROM sys.schemas WHERE schema_name = 'public')" in restricted_tables_catalog,
        "catalog restriction should normalize through schema predicate",
    )
    var restricted_index_columns_index = conn.query_metadata_restricted("index_columns", "index", "idx_orders")
    _require(
        "index_id IN (SELECT index_id FROM sys.indexes WHERE index_name LIKE 'idx_orders' ESCAPE '\\')" in restricted_index_columns_index,
        "index_columns index restriction should map through index-name subquery",
    )
    var restricted_constraints = conn.query_metadata_restricted("constraints", "constraint", "orders_pk")
    _require(
        "constraint_name LIKE 'orders_pk' ESCAPE '\\'" in restricted_constraints,
        "constraint restriction should target constraint_name",
    )
    var restricted_routines = conn.query_metadata_restricted("routines", "routine", "orders_upsert")
    _require(
        "routine_name LIKE 'orders_upsert' ESCAPE '\\'" in restricted_routines,
        "routine restriction should target routine_name",
    )
    var restricted_columns_type = conn.query_metadata_restricted("columns", "type", "INTEGER")
    _require(
        "data_type_name = 'INTEGER'" in restricted_columns_type,
        "type restriction should target data_type_name",
    )
    _require(
        conn.query_metadata_rows_restricted("routines", "schema", "public") == 1,
        "routines schema restriction rowcount mismatch",
    )
    _require(
        conn.query_metadata_restricted("tables", "table_name", "") == scratchbird_native.METADATA_TABLES_QUERY,
        "empty restriction value should not mutate metadata query",
    )
    _require(
        scratchbird_native.normalize_metadata_collection_name("column") == "columns",
        "metadata column alias mismatch",
    )
    _require(
        scratchbird_native.normalize_metadata_collection_name("foreignkey") == "foreign_keys",
        "metadata foreignkey alias mismatch",
    )
    _require(
        scratchbird_native.normalize_metadata_collection_name("tableprivileges") == "table_privileges",
        "metadata tableprivileges alias mismatch",
    )
    _require(
        scratchbird_native.normalize_metadata_restriction_key("TABLE_SCHEM") == "schema_name",
        "metadata restriction alias mismatch for TABLE_SCHEM",
    )
    _require(
        scratchbird_native.normalize_metadata_restriction_key("column") == "column_name",
        "metadata restriction alias mismatch for column",
    )
    _assert_metadata_guard("unsupported_collection", "0A000", "not supported")
    _assert_metadata_restriction_guard("tables", "unsupported_restriction", "0A000", "not supported")
    _assert_metadata_restriction_guard("tables", "column", "0A000", "not supported for 'tables'")
    _assert_metadata_restriction_count_guard("tables")

    var stream = conn.stream("SELECT id FROM basic_table ORDER BY id", 1)
    _require(stream.next(conn) == 1, "stream first row mismatch")
    _require(stream.next(conn) == 2, "stream second row mismatch")
    stream.close()
    try:
        _ = stream.next(conn)
        raise Error("expected closed stream to fail")
    except e:
        _require("stream exhausted" in String(e), "closed stream should report exhaustion")

    var long_stream = conn.stream(
        "SELECT a.id FROM basic_table a, basic_table b, basic_table c, basic_table d, basic_table e",
        1,
    )
    _ = long_stream.next(conn)
    conn.cancel()
    try:
        _ = long_stream.next(conn)
        raise Error("expected cancelled stream to fail")
    except e:
        _require("57014" in String(e), "cancelled stream should report 57014")
    var post_cancel = conn.stream("SELECT id FROM basic_table ORDER BY id", 1)
    _require(post_cancel.next(conn) == 1, "post-cancel stream should recover on next operation")
    post_cancel.close()
    var metrics = conn.telemetry.get_metrics()
    _require(len(metrics) > 0 and "total_queries=" in metrics[0], "telemetry metrics should be recorded")
    _require("count=" in conn.telemetry.operation_metrics("query"), "query operation metrics should be recorded")
    _require(not conn.circuit_breaker.is_open(), "circuit breaker should remain closed")
    _require(conn.keepalive_tracker.last_activity_ms > 0, "keepalive tracker should mark activity")
    _require(conn.query_pipeline.completed_count() > 0, "pipeline should record completed requests")
    _require(conn.leak_detector.get_active_count() == 1, "leak detector should track active checkout")

    var keepalive_cfg = scratchbird_native.ScratchBirdConfig(
        "scratchbird://user:pass@localhost:3092/testdb?sslmode=require&keepalive_max_idle_before_check_ms=0"
    )
    var keepalive_conn = scratchbird_native.connect(keepalive_cfg)
    _ = keepalive_conn.query("SELECT 1")
    keepalive_conn.operation_clock_ms += 2
    _ = keepalive_conn.query("SELECT 1")
    _require(keepalive_conn.ping_count >= 1, "keepalive validation should trigger ping")
    keepalive_conn.close()

    var pipeline_cfg = scratchbird_native.ScratchBirdConfig(
        "scratchbird://user:pass@localhost:3092/testdb?sslmode=require&pipeline_max_in_flight=0"
    )
    var pipeline_conn = scratchbird_native.connect(pipeline_cfg)
    try:
        _ = pipeline_conn.query("SELECT 1")
        raise Error("expected pipeline capacity guard")
    except e:
        _require(
            scratchbird_native.extract_sqlstate(String(e)) == "54000",
            "pipeline capacity guard should expose 54000",
        )
    pipeline_conn.close()

    var breaker_cfg = scratchbird_native.ScratchBirdConfig(
        "scratchbird://user:pass@localhost:3092/testdb?sslmode=require&cb_failure_threshold=2"
    )
    var breaker_conn = scratchbird_native.connect(breaker_cfg)
    try:
        _ = breaker_conn.query("SELECT unsupported_query")
    except e:
        _require(
            scratchbird_native.extract_sqlstate(String(e)) == "0A000",
            "first breaker failure should preserve unsupported query sqlstate",
        )
    try:
        _ = breaker_conn.query("SELECT unsupported_query")
    except e:
        _require(
            scratchbird_native.extract_sqlstate(String(e)) == "0A000",
            "second breaker failure should preserve unsupported query sqlstate",
        )
    try:
        _ = breaker_conn.query("SELECT 1")
        raise Error("expected circuit breaker guard")
    except e:
        _require(
            scratchbird_native.extract_sqlstate(String(e)) == "08006",
            "circuit breaker guard should expose 08006",
        )
    breaker_conn.close()

    var leak_cfg = scratchbird_native.ScratchBirdConfig(
        "scratchbird://user:pass@localhost:3092/testdb?sslmode=require&leak_threshold_ms=0"
    )
    var leak_conn = scratchbird_native.connect(leak_cfg)
    _ = leak_conn.query("SELECT 1")
    leak_conn.close()
    _require(
        len(leak_conn.leak_detector.get_warnings()) > 0,
        "leak detector should record warning when threshold is zero",
    )

    var pipeline_auto_cfg = scratchbird_native.ScratchBirdConfig(
        "scratchbird://user:pass@localhost:3092/testdb?sslmode=require&pipeline_auto_flush=true&pipeline_auto_flush_threshold=1"
    )
    var pipeline_auto_conn = scratchbird_native.connect(pipeline_auto_cfg)
    _ = pipeline_auto_conn.query("SELECT 1")
    _ = pipeline_auto_conn.query("SELECT 1")
    _require(pipeline_auto_conn.query_pipeline.pending_count() == 0, "auto-flush pipeline should not retain pending work")
    _require(
        pipeline_auto_conn.query_pipeline.completed_count() >= 2,
        "auto-flush pipeline should complete queued requests",
    )
    pipeline_auto_conn.close()

    var pipeline_manual_cfg = scratchbird_native.ScratchBirdConfig(
        "scratchbird://user:pass@localhost:3092/testdb?sslmode=require&pipeline_auto_flush=false&pipeline_max_in_flight=2"
    )
    var pipeline_manual_conn = scratchbird_native.connect(pipeline_manual_cfg)
    _ = pipeline_manual_conn.query("SELECT 1")
    _ = pipeline_manual_conn.query("SELECT 1")
    _require(
        pipeline_manual_conn.query_pipeline.pending_count() == 2,
        "manual pipeline should retain pending requests until flush/close",
    )
    try:
        _ = pipeline_manual_conn.query("SELECT 1")
        raise Error("expected manual pipeline capacity guard")
    except e:
        _require(
            scratchbird_native.extract_sqlstate(String(e)) == "54000",
            "manual pipeline capacity guard should expose 54000",
        )
    pipeline_manual_conn.close()
    _require(
        pipeline_manual_conn.query_pipeline.completed_count() >= 2,
        "manual pipeline close should flush retained requests",
    )

    var breaker_recovery_cfg = scratchbird_native.ScratchBirdConfig(
        "scratchbird://user:pass@localhost:3092/testdb?sslmode=require&cb_failure_threshold=1&cb_recovery_timeout_ms=2&cb_success_threshold=2&cb_half_open_max_requests=1"
    )
    var breaker_recovery_conn = scratchbird_native.connect(breaker_recovery_cfg)
    try:
        _ = breaker_recovery_conn.query("SELECT unsupported_query")
        raise Error("expected initial breaker failure")
    except e:
        _require(
            scratchbird_native.extract_sqlstate(String(e)) == "0A000",
            "initial breaker failure should preserve unsupported query sqlstate",
        )
    _require(breaker_recovery_conn.circuit_breaker.is_open(), "breaker should open after threshold failure")
    try:
        _ = breaker_recovery_conn.query("SELECT 1")
        raise Error("expected breaker-open guard before recovery timeout")
    except e:
        _require(
            scratchbird_native.extract_sqlstate(String(e)) == "08006",
            "breaker-open guard should expose 08006",
        )
    breaker_recovery_conn.operation_clock_ms += 3
    _ = breaker_recovery_conn.query("SELECT 1")
    _require(
        breaker_recovery_conn.circuit_breaker.is_half_open(),
        "first recovery success should leave breaker half-open with success threshold > 1",
    )
    _ = breaker_recovery_conn.query("SELECT 1")
    _require(
        not breaker_recovery_conn.circuit_breaker.is_open(),
        "recovery successes should close breaker",
    )
    breaker_recovery_conn.close()

    try:
        _ = conn.query("SELECT unsupported_query")
        raise Error("expected unsupported query to fail")
    except e:
        _require(
            scratchbird_native.extract_sqlstate(String(e)) == "0A000",
            "unsupported query should expose 0A000",
        )

    try:
        _ = conn.stream("SELECT unsupported_stream_query", 1)
        raise Error("expected unsupported stream query to fail")
    except e:
        _require(
            scratchbird_native.extract_sqlstate(String(e)) == "0A000",
            "unsupported stream query should expose 0A000",
        )
    conn.close()
    _require(conn.leak_detector.get_active_count() == 0, "leak detector should release checkout on close")
    _require(not conn.query_pipeline.running, "pipeline should stop on close")

    var manager_cfg = scratchbird_native.ScratchBirdConfig(
        "scratchbird://user:pass@localhost:3092/testdb?front_door_mode=manager_proxy"
    )
    _require(manager_cfg.front_door_mode == "manager_proxy", "front_door_mode manager_proxy mismatch")
    _ = scratchbird_native.connect(manager_cfg)
    var manager_dash_cfg = scratchbird_native.ScratchBirdConfig(
        "scratchbird://user:pass@localhost:3092/testdb?front_door_mode=manager-proxy"
    )
    _require(manager_dash_cfg.front_door_mode == "manager_proxy", "front_door_mode manager-proxy normalization mismatch")
    _ = scratchbird_native.connect(manager_dash_cfg)
    _ = scratchbird_native.connect(cfg_connection_mode_alias)
    _ = scratchbird_native.connect(cfg_ingress_mode_alias)
    _ = scratchbird_native.connect(cfg_credential_override)
    _ = scratchbird_native.connect(cfg_credential_override_hostonly)

    _assert_connect_guard(
        "scratchbird://user:pass@localhost:3092/testdb?sslmode=disable",
        "08004",
        "TLS is required for ScratchBird connections",
    )
    _assert_connect_guard(
        "scratchbird://user:pass@localhost:3092/testdb?binary_transfer=false",
        "0A000",
        "binary_transfer=false is not supported",
    )
    _assert_connect_guard(
        "scratchbird://user:pass@localhost:3092/testdb?compression=zstd",
        "0A000",
        "compression=zstd is not supported",
    )
    _assert_connect_guard(
        "scratchbird://user:pass@localhost:3092/testdb?sb_test_auth_fail=true",
        "28P01",
        "authentication failed",
    )
    _assert_connect_guard(
        "scratchbird://user:pass@localhost:3092/testdb?front_door_mode=invalid",
        "22023",
        "front_door_mode must be direct or manager_proxy.",
    )
    _assert_connect_guard(
        "scratchbird://@localhost:3092/?sslmode=require",
        "28000",
        "user and database are required",
    )
    _assert_connect_guard(
        "scratchbird://user:pass@:3092/testdb?sslmode=require",
        "28000",
        "host and database are required",
    )
    _assert_connect_guard(
        "scratchbird://user:pass@localhost:3092/testdb?sslmode=require&port=0",
        "22023",
        "port must be positive",
    )
    _assert_connect_guard(
        "scratchbird://user:pass@localhost:3092/testdb?sslmode=require&port=70000",
        "22023",
        "port must be between 1 and 65535",
    )
    _assert_connect_guard(
        "scratchbird://user:pass@localhost:3092/testdb?sslmode=require&connecttimeout=-1",
        "22023",
        "connect_timeout must be >= 0",
    )
    _assert_connect_guard(
        "scratchbird://user:pass@localhost:3092/testdb?sslmode=require&sockettimeout=-1",
        "22023",
        "socket_timeout must be >= 0",
    )
    _assert_connect_guard(
        "scratchbird://user:pass@localhost:3092/testdb?sslmode=require&login_timeout=-1",
        "22023",
        "login_timeout must be >= 0",
    )

    print("Mojo native bootstrap tests OK")
