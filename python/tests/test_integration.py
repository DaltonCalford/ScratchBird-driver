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
        cur.execute("SELECT * FROM sb_conformance.type_coverage")
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
