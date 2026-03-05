# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

import scratchbird
from collections import List


fn _require(condition: Bool, message: String) raises:
    if not condition:
        raise Error(message)


fn _assert_connect_guard(dsn: String, expected_sqlstate: String, expected_fragment: String) raises:
    var cfg = scratchbird.ScratchBirdConfig(dsn)
    try:
        _ = scratchbird.connect(cfg)
        raise Error("expected connect guard to reject DSN")
    except e:
        var message = String(e)
        _require(
            scratchbird.extract_sqlstate(message) == expected_sqlstate,
            "expected sqlstate '" + expected_sqlstate + "', got '" + scratchbird.extract_sqlstate(message) + "'",
        )
        _require(
            expected_fragment in message,
            "expected message containing '" + expected_fragment + "', got '" + message + "'",
        )


fn _assert_metadata_restriction_guard(
    collection_name: String,
    restriction_key: String,
    expected_sqlstate: String,
    expected_fragment: String,
) raises:
    try:
        _ = scratchbird.metadata_query_restricted(collection_name, restriction_key, "x")
        raise Error("expected metadata restriction guard to reject restriction")
    except e:
        var message = String(e)
        _require(
            scratchbird.extract_sqlstate(message) == expected_sqlstate,
            "expected metadata restriction sqlstate '" + expected_sqlstate + "', got '" + scratchbird.extract_sqlstate(message) + "'",
        )
        _require(
            expected_fragment in message,
            "expected metadata restriction guard containing '" + expected_fragment + "', got '" + message + "'",
        )


fn main() raises:
    var cfg = scratchbird.ScratchBirdConfig(
        "scratchbird://user:pass@localhost:3092/testdb?sslmode=require&binary_transfer=true"
    )
    _require(cfg.user == "user", "user parse mismatch")
    _require(cfg.database == "testdb", "database parse mismatch")

    var conn = scratchbird.connect(cfg)
    _require(conn.ping(), "ping should return true")
    _require(conn.query("SELECT 1") == 1, "SELECT 1 should return 1")

    var p1 = List[String]()
    p1.append("41")
    _require(conn.query_with_params("SELECT $1::INTEGER", p1) == 41, "single-parameter query mismatch")

    var p2 = List[String]()
    p2.append("7")
    p2.append("8")
    var stmt = conn.prepare("SELECT $1::INTEGER, $2::INTEGER")
    _require(stmt.execute(p2) == 15, "prepared execute mismatch")

    _require(
        conn.query_metadata("table") == scratchbird.METADATA_TABLES_QUERY,
        "metadata table alias mismatch",
    )
    _require(
        conn.query_metadata_rows("typeinfo") == 1,
        "metadata typeinfo rowcount mismatch",
    )
    _require(
        scratchbird.metadata_query("foreignkey") == scratchbird.METADATA_FOREIGN_KEYS_QUERY,
        "metadata_query alias mismatch",
    )
    _require(
        scratchbird.normalize_metadata_collection_name("columnprivileges") == "column_privileges",
        "metadata alias normalization mismatch",
    )
    var restricted_tables = conn.query_metadata_restricted("table", "name", "orders")
    _require(
        restricted_tables
        == "SELECT table_id, schema_id, table_name, table_type, owner_id FROM sys.tables WHERE is_valid = 1 AND table_name = 'orders' ORDER BY table_name",
        "restricted metadata table query mismatch",
    )
    _require(
        conn.query_metadata_rows_restricted("table", "name", "orders") == 1,
        "restricted metadata rowcount mismatch",
    )
    _require(
        scratchbird.metadata_query_restricted("tables", "table_name", "") == scratchbird.METADATA_TABLES_QUERY,
        "empty restriction value should not mutate metadata query",
    )
    _require(
        scratchbird.normalize_metadata_restriction_key("table_schem") == "schema_name",
        "metadata restriction alias mismatch for table_schem",
    )
    _assert_metadata_restriction_guard("tables", "unsupported_restriction", "0A000", "not supported")
    _assert_metadata_restriction_guard("tables", "schema", "0A000", "not supported for 'tables'")

    var stream = conn.stream("SELECT id FROM basic_table ORDER BY id", 1)
    _require(stream.next(conn) == 1, "stream first row mismatch")
    conn.cancel()
    try:
        _ = stream.next(conn)
        raise Error("expected cancelled stream to fail")
    except e:
        _require("57014" in String(e), "cancelled stream should report 57014")

    var post_cancel = conn.stream("SELECT id FROM basic_table ORDER BY id", 1)
    _require(post_cancel.next(conn) == 1, "post-cancel stream should recover")
    post_cancel.close()
    var metrics = conn.telemetry.get_metrics()
    _require(len(metrics) > 0 and "total_queries=" in metrics[0], "telemetry metrics should be recorded")
    _require("count=" in conn.telemetry.operation_metrics("query"), "query operation metrics should be recorded")
    _require(not conn.circuit_breaker.is_open(), "circuit breaker should remain closed")
    _require(conn.keepalive_tracker.last_activity_ms > 0, "keepalive tracker should mark activity")
    _require(conn.query_pipeline.completed_count() > 0, "pipeline should record completed requests")
    _require(conn.leak_detector.get_active_count() == 1, "leak detector should track active checkout")
    conn.close()
    _require(conn.leak_detector.get_active_count() == 0, "leak detector should release checkout on close")
    _require(not conn.query_pipeline.running, "pipeline should stop on close")

    var keepalive_cfg = scratchbird.ScratchBirdConfig(
        "scratchbird://user:pass@localhost:3092/testdb?sslmode=require&keepalive_max_idle_before_check_ms=0"
    )
    var keepalive_conn = scratchbird.connect(keepalive_cfg)
    _ = keepalive_conn.query("SELECT 1")
    keepalive_conn.operation_clock_ms += 2
    _ = keepalive_conn.query("SELECT 1")
    _require(keepalive_conn.ping_count >= 1, "keepalive validation should trigger ping")
    keepalive_conn.close()

    var pipeline_cfg = scratchbird.ScratchBirdConfig(
        "scratchbird://user:pass@localhost:3092/testdb?sslmode=require&pipeline_max_in_flight=0"
    )
    var pipeline_conn = scratchbird.connect(pipeline_cfg)
    try:
        _ = pipeline_conn.query("SELECT 1")
        raise Error("expected pipeline capacity guard")
    except e:
        _require(
            scratchbird.extract_sqlstate(String(e)) == "54000",
            "pipeline capacity guard should expose 54000",
        )
    pipeline_conn.close()

    var breaker_cfg = scratchbird.ScratchBirdConfig(
        "scratchbird://user:pass@localhost:3092/testdb?sslmode=require&cb_failure_threshold=2"
    )
    var breaker_conn = scratchbird.connect(breaker_cfg)
    try:
        _ = breaker_conn.query("SELECT unsupported_query")
    except e:
        _require(
            scratchbird.extract_sqlstate(String(e)) == "0A000",
            "first breaker failure should preserve unsupported query sqlstate",
        )
    try:
        _ = breaker_conn.query("SELECT unsupported_query")
    except e:
        _require(
            scratchbird.extract_sqlstate(String(e)) == "0A000",
            "second breaker failure should preserve unsupported query sqlstate",
        )
    try:
        _ = breaker_conn.query("SELECT 1")
        raise Error("expected circuit breaker guard")
    except e:
        _require(
            scratchbird.extract_sqlstate(String(e)) == "08006",
            "circuit breaker guard should expose 08006",
        )
    breaker_conn.close()

    var leak_cfg = scratchbird.ScratchBirdConfig(
        "scratchbird://user:pass@localhost:3092/testdb?sslmode=require&leak_threshold_ms=0"
    )
    var leak_conn = scratchbird.connect(leak_cfg)
    _ = leak_conn.query("SELECT 1")
    leak_conn.close()
    _require(
        len(leak_conn.leak_detector.get_warnings()) > 0,
        "leak detector should record warning when threshold is zero",
    )

    var pipeline_auto_cfg = scratchbird.ScratchBirdConfig(
        "scratchbird://user:pass@localhost:3092/testdb?sslmode=require&pipeline_auto_flush=true&pipeline_auto_flush_threshold=1"
    )
    var pipeline_auto_conn = scratchbird.connect(pipeline_auto_cfg)
    _ = pipeline_auto_conn.query("SELECT 1")
    _ = pipeline_auto_conn.query("SELECT 1")
    _require(pipeline_auto_conn.query_pipeline.pending_count() == 0, "auto-flush pipeline should not retain pending work")
    _require(
        pipeline_auto_conn.query_pipeline.completed_count() >= 2,
        "auto-flush pipeline should complete queued requests",
    )
    pipeline_auto_conn.close()

    var pipeline_manual_cfg = scratchbird.ScratchBirdConfig(
        "scratchbird://user:pass@localhost:3092/testdb?sslmode=require&pipeline_auto_flush=false&pipeline_max_in_flight=2"
    )
    var pipeline_manual_conn = scratchbird.connect(pipeline_manual_cfg)
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
            scratchbird.extract_sqlstate(String(e)) == "54000",
            "manual pipeline capacity guard should expose 54000",
        )
    pipeline_manual_conn.close()
    _require(
        pipeline_manual_conn.query_pipeline.completed_count() >= 2,
        "manual pipeline close should flush retained requests",
    )

    var breaker_recovery_cfg = scratchbird.ScratchBirdConfig(
        "scratchbird://user:pass@localhost:3092/testdb?sslmode=require&cb_failure_threshold=1&cb_recovery_timeout_ms=2&cb_success_threshold=2&cb_half_open_max_requests=1"
    )
    var breaker_recovery_conn = scratchbird.connect(breaker_recovery_cfg)
    try:
        _ = breaker_recovery_conn.query("SELECT unsupported_query")
        raise Error("expected initial breaker failure")
    except e:
        _require(
            scratchbird.extract_sqlstate(String(e)) == "0A000",
            "initial breaker failure should preserve unsupported query sqlstate",
        )
    _require(breaker_recovery_conn.circuit_breaker.is_open(), "breaker should open after threshold failure")
    try:
        _ = breaker_recovery_conn.query("SELECT 1")
        raise Error("expected breaker-open guard before recovery timeout")
    except e:
        _require(
            scratchbird.extract_sqlstate(String(e)) == "08006",
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

    print("Mojo scratchbird facade tests OK")
