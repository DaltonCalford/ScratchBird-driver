# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
from __future__ import annotations

from scratchbird.sql import normalize_query


def test_normalize_positional():
    sql = "SELECT ?"
    rewritten, params = normalize_query(sql, (1,))
    assert rewritten == "SELECT $1"
    assert params == [1]


def test_normalize_named():
    sql = "SELECT :id, @name"
    rewritten, params = normalize_query(sql, {"id": 1, "name": "Ada"})
    assert rewritten == "SELECT $1, $2"
    assert params == [1, "Ada"]


def test_normalize_named_preserves_cast_syntax():
    sql = "SELECT :id::INTEGER"
    rewritten, params = normalize_query(sql, {"id": 1})
    assert rewritten == "SELECT $1::INTEGER"
    assert params == [1]
