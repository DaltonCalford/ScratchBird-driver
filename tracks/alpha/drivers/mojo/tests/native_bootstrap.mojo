# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

import scratchbird_native


fn _require(condition: Bool, message: String) raises:
    if not condition:
        raise Error(message)


fn _assert_connect_guard(dsn: String, expected_fragment: String) raises:
    var cfg = scratchbird_native.ScratchBirdConfig(dsn)
    try:
        _ = scratchbird_native.connect(cfg)
        raise Error("expected connect guard to reject DSN")
    except e:
        var message = String(e)
        _require(
            expected_fragment in message,
            "expected guard message containing '" + expected_fragment + "', got '" + message + "'",
        )


fn _assert_metadata_guard(collection_name: String, expected_fragment: String) raises:
    try:
        _ = scratchbird_native.normalize_metadata_collection_name(collection_name)
        raise Error("expected metadata guard to reject collection")
    except e:
        var message = String(e)
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
    _require(conn.query("SELECT 1") == 1, "SELECT 1 should return 1")
    _require(conn.query("SELECT * FROM type_coverage") == 1, "type_coverage stub should return success")
    _require(
        conn.query_metadata("table") == scratchbird_native.METADATA_TABLES_QUERY,
        "metadata table alias mismatch",
    )
    _require(
        conn.query_metadata("schemas") == scratchbird_native.METADATA_SCHEMAS_QUERY,
        "metadata schemas query mismatch",
    )
    _require(
        scratchbird_native.normalize_metadata_collection_name("column") == "columns",
        "metadata column alias mismatch",
    )
    _assert_metadata_guard("unsupported_collection", "not supported")
    conn.close()

    var manager_cfg = scratchbird_native.ScratchBirdConfig(
        "scratchbird://user:pass@localhost:3092/testdb?front_door_mode=manager_proxy"
    )
    _ = scratchbird_native.connect(manager_cfg)

    _assert_connect_guard(
        "scratchbird://user:pass@localhost:3092/testdb?sslmode=disable",
        "TLS is required for ScratchBird connections",
    )
    _assert_connect_guard(
        "scratchbird://user:pass@localhost:3092/testdb?binary_transfer=false",
        "binary_transfer=false is not supported",
    )
    _assert_connect_guard(
        "scratchbird://user:pass@localhost:3092/testdb?compression=zstd",
        "compression=zstd is not supported",
    )
    _assert_connect_guard(
        "scratchbird://user:pass@localhost:3092/testdb?front_door_mode=invalid",
        "front_door_mode must be direct or manager_proxy.",
    )
    _assert_connect_guard(
        "scratchbird://@localhost:3092/?sslmode=require",
        "user and database are required",
    )

    print("Mojo native bootstrap tests OK")
