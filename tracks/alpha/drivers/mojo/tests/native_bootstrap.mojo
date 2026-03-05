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


fn main() raises:
    var cfg = scratchbird_native.ScratchBirdConfig(
        "scratchbird://user:pass@localhost:3092/testdb?sslmode=require&binary_transfer=true"
    )
    _require(cfg.user == "user", "user parse mismatch")
    _require(cfg.database == "testdb", "database parse mismatch")

    var conn = scratchbird_native.connect(cfg)
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
    _assert_metadata_guard("unsupported_collection", "0A000", "not supported")

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
    _ = scratchbird_native.connect(manager_cfg)

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
        "scratchbird://user:pass@localhost:3092/testdb?front_door_mode=invalid",
        "22023",
        "front_door_mode must be direct or manager_proxy.",
    )
    _assert_connect_guard(
        "scratchbird://@localhost:3092/?sslmode=require",
        "28000",
        "user and database are required",
    )

    print("Mojo native bootstrap tests OK")
