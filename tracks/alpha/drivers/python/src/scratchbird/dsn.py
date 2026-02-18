# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
"""DSN parsing helpers for ScratchBird Python driver."""

from __future__ import annotations

import urllib.parse


def normalize_native_protocol(value: str | None) -> str:
    normalized = (value or "").strip().lower()
    if normalized in ("", "native", "scratchbird", "scratchbird-native", "scratchbird_native"):
        return "native"
    raise ValueError("Only protocol=native is supported; connect to the native parser listener/port.")


def parse_dsn(dsn: str | None) -> dict:
    if not dsn:
        return {}

    if "://" in dsn:
        return _parse_uri(dsn)
    return _parse_kv(dsn)


def _parse_uri(dsn: str) -> dict:
    parsed = urllib.parse.urlparse(dsn)
    if parsed.scheme not in ("scratchbird", "sb"):
        raise ValueError(f"Unsupported DSN scheme: {parsed.scheme}")

    params = {}
    if parsed.hostname:
        params["host"] = parsed.hostname
    if parsed.port:
        params["port"] = parsed.port
    if parsed.username:
        params["user"] = urllib.parse.unquote(parsed.username)
    if parsed.password:
        params["password"] = urllib.parse.unquote(parsed.password)
    if parsed.path and parsed.path != "/":
        params["database"] = parsed.path.lstrip("/")

    query = urllib.parse.parse_qs(parsed.query, keep_blank_values=True)
    for key, values in query.items():
        if values:
            params[key] = values[-1]
    return params


def _parse_kv(dsn: str) -> dict:
    params = {}
    tokens = dsn.split()
    for token in tokens:
        if "=" not in token:
            continue
        key, value = token.split("=", 1)
        params[key.strip()] = value.strip()
    return params
