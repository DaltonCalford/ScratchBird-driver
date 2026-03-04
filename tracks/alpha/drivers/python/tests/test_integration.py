# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
from __future__ import annotations

import os
import threading
import time

import pytest

import scratchbird


def test_basic_query_integration():
    dsn = os.environ.get("SCRATCHBIRD_TEST_DSN")
    if not dsn:
        pytest.skip("SCRATCHBIRD_TEST_DSN not set")
    conn = scratchbird.connect(dsn)
    try:
        cur = conn.cursor()
        cur.execute("SELECT 1")
        row = cur.fetchone()
        assert row == (1,)
    finally:
        conn.close()


def test_prepare_bind_integration():
    dsn = os.environ.get("SCRATCHBIRD_TEST_DSN")
    if not dsn:
        pytest.skip("SCRATCHBIRD_TEST_DSN not set")
    conn = scratchbird.connect(dsn)
    try:
        cur = conn.cursor()
        cur.execute("SELECT ?::INTEGER", (42,))
        row = cur.fetchone()
        assert row == (42,)
    finally:
        conn.close()


def test_types_fixture_integration():
    dsn = os.environ.get("SCRATCHBIRD_TEST_DSN")
    if not dsn:
        pytest.skip("SCRATCHBIRD_TEST_DSN not set")
    conn = scratchbird.connect(dsn)
    try:
        cur = conn.cursor()
        cur.execute("SELECT * FROM type_coverage")
        row = cur.fetchone()
        assert row is not None
        assert len(row) > 0
    finally:
        conn.close()


def test_cancel_integration():
    dsn = os.environ.get("SCRATCHBIRD_TEST_DSN")
    if not dsn:
        pytest.skip("SCRATCHBIRD_TEST_DSN not set")
    cancel_sql = os.environ.get("SCRATCHBIRD_TEST_CANCEL_SQL")
    if not cancel_sql:
        pytest.skip("SCRATCHBIRD_TEST_CANCEL_SQL not set")
    conn = scratchbird.connect(dsn)
    error = []

    def run_query():
        try:
            cur = conn.cursor()
            cur.execute(cancel_sql)
            cur.fetchall()
        except Exception as exc:  # noqa: BLE001
            error.append(exc)

    thread = threading.Thread(target=run_query)
    thread.start()
    time.sleep(0.2)
    conn.cancel()
    thread.join(timeout=5)
    conn.close()
    assert error, "expected cancel error"


def test_query_multi_integration():
    dsn = os.environ.get("SCRATCHBIRD_TEST_DSN")
    if not dsn:
        pytest.skip("SCRATCHBIRD_TEST_DSN not set")
    conn = scratchbird.connect(dsn)
    try:
        result_sets = conn.query_multi("SELECT 1; SELECT 2")
        assert len(result_sets) == 2
        assert result_sets[0]["rows"] == [(1,)]
        assert result_sets[1]["rows"] == [(2,)]
    finally:
        conn.close()


def test_execute_multi_alias_integration():
    dsn = os.environ.get("SCRATCHBIRD_TEST_DSN")
    if not dsn:
        pytest.skip("SCRATCHBIRD_TEST_DSN not set")
    conn = scratchbird.connect(dsn)
    try:
        result_sets = conn.execute_multi("SELECT 3; SELECT 4")
        assert len(result_sets) == 2
        assert result_sets[0]["rows"] == [(3,)]
        assert result_sets[1]["rows"] == [(4,)]
    finally:
        conn.close()


def test_execute_batch_integration():
    dsn = os.environ.get("SCRATCHBIRD_TEST_DSN")
    if not dsn:
        pytest.skip("SCRATCHBIRD_TEST_DSN not set")
    conn = scratchbird.connect(dsn)
    try:
        batch = conn.execute_batch("SELECT ?::INTEGER", [(11,), (22,)])
        assert batch["totalRowCount"] >= 0
        assert [item["index"] for item in batch["items"]] == [0, 1]
        assert len(batch["items"]) == 2
    finally:
        conn.close()


def test_execute_with_generated_keys_integration():
    dsn = os.environ.get("SCRATCHBIRD_TEST_DSN")
    if not dsn:
        pytest.skip("SCRATCHBIRD_TEST_DSN not set")
    conn = scratchbird.connect(dsn)
    try:
        keys = conn.execute_with_generated_keys("SELECT 1")
        rows = keys.fetchall()
        assert len(rows) == 1
        assert isinstance(rows[0][0], int)
    finally:
        conn.close()
