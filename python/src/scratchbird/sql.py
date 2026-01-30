# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
"""SQL parameter normalization helpers."""

from __future__ import annotations

from typing import Any, Dict, List, Tuple


def normalize_query(sql: str, params) -> Tuple[str, List[Any]]:
    if params is None:
        return sql, []
    if isinstance(params, dict):
        if not _has_named_params(sql):
            raise ValueError("named parameters provided but query has no placeholders")
        return _rewrite_named(sql, params)
    values = list(params)
    if "?" in sql:
        return _rewrite_positional(sql, values)
    return sql, values


def _has_named_params(sql: str) -> bool:
    in_string = False
    for i in range(len(sql) - 1):
        ch = sql[i]
        if ch == "'":
            in_string = not in_string
            continue
        if in_string:
            continue
        if ch in (":", "@") and sql[i + 1].isidentifier():
            return True
    return False


def _rewrite_named(sql: str, params: Dict[str, Any]) -> Tuple[str, List[Any]]:
    result = []
    ordered: List[Any] = []
    i = 0
    in_string = False
    while i < len(sql):
        ch = sql[i]
        if ch == "'" and i + 1 < len(sql):
            in_string = not in_string
            result.append(ch)
            i += 1
            continue
        if not in_string and ch in (":", "@") and i + 1 < len(sql) and sql[i + 1].isidentifier():
            j = i + 1
            while j < len(sql) and (sql[j].isalnum() or sql[j] == "_"):
                j += 1
            key = sql[i + 1 : j]
            if key not in params:
                raise ValueError(f"missing named parameter: {key}")
            ordered.append(params[key])
            result.append(f"${len(ordered)}")
            i = j
            continue
        result.append(ch)
        i += 1
    return "".join(result), ordered


def _rewrite_positional(sql: str, values: List[Any]) -> Tuple[str, List[Any]]:
    result = []
    ordered: List[Any] = []
    i = 0
    in_string = False
    idx = 0
    while i < len(sql):
        ch = sql[i]
        if ch == "'" and i + 1 < len(sql):
            in_string = not in_string
            result.append(ch)
            i += 1
            continue
        if not in_string and ch == "?":
            if idx >= len(values):
                raise ValueError("not enough parameters")
            ordered.append(values[idx])
            idx += 1
            result.append(f"${len(ordered)}")
            i += 1
            continue
        result.append(ch)
        i += 1
    if idx < len(values):
        raise ValueError("too many parameters")
    return "".join(result), ordered
