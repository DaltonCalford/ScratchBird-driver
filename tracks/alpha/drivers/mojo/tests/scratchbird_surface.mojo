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
    conn.close()

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
