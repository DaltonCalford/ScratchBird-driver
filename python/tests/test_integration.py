from __future__ import annotations

import os

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
