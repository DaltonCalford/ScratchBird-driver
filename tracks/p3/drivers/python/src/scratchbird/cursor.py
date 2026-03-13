# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
"""Cursor implementation for ScratchBird Python driver."""

from __future__ import annotations

from typing import Iterable, List, Optional

from . import errors
from .sql import normalize_callable_query


class GeneratedKeysResultSet:
    _DESCRIPTION = [
        (
            "GENERATED_KEY",
            20,
            None,
            None,
            None,
            None,
            True,
        )
    ]

    def __init__(self, rows):
        self._rows = list(rows)
        self._pos = 0
        self.description = list(self._DESCRIPTION)

    @property
    def rowcount(self) -> int:
        return len(self._rows)

    def fetchone(self):
        if self._pos >= len(self._rows):
            return None
        row = self._rows[self._pos]
        self._pos += 1
        return row

    def fetchmany(self, size: int = 1):
        if size <= 0:
            return []
        rows = []
        while len(rows) < size:
            row = self.fetchone()
            if row is None:
                break
            rows.append(row)
        return rows

    def fetchall(self):
        if self._pos >= len(self._rows):
            return []
        rows = self._rows[self._pos :]
        self._pos = len(self._rows)
        return list(rows)


class Cursor:
    def __init__(self, connection):
        self._connection = connection
        self._closed = False
        self._results: List = []
        self._pos = 0
        self._stream = None
        self.description = None
        self.rowcount = -1
        self.arraysize = 1
        self.lastrowid = None
        self.statusmessage = None
        self._generated_keys: List[tuple] = []
        self._last_completion_count = 0

    def execute(self, sql: str, params=None) -> None:
        self._ensure_open()
        if sql is None:
            raise errors.ProgrammingError("sql is required")
        self._reset_state()
        page_size = self.arraysize if self.arraysize and self.arraysize > 1 else 0
        self._stream = self._connection._execute_query(sql, params, page_size)
        self._prime_stream_metadata(self._stream)
        self._results = []
        self._pos = 0
        self._update_description(self._stream)
        self.rowcount = -1
        self.statusmessage = None

    def executemany(self, sql: str, seq_of_params: Iterable) -> None:
        self._ensure_open()
        if sql is None:
            raise errors.ProgrammingError("sql is required")
        if seq_of_params is None:
            raise errors.ProgrammingError("seq_of_params is required")
        self._reset_state()
        total = 0
        rowcount_known = True
        page_size = self.arraysize if self.arraysize and self.arraysize > 1 else 0
        for params in seq_of_params:
            stream = self._connection._execute_query(sql, params, page_size)
            self._prime_stream_metadata(stream)
            self._stream = stream
            self._results = []
            self._pos = 0
            self._update_description(stream)
            rowcount = self._drain_stream(stream)
            if rowcount is None or rowcount < 0:
                rowcount_known = False
            else:
                total += rowcount
        self.rowcount = total if rowcount_known else -1

    def callproc(self, procname: str, params=None):
        self._ensure_open()
        if not isinstance(procname, str) or not procname.strip():
            raise errors.ProgrammingError("procname is required")

        routine = procname.strip()
        if params is None:
            sql = f"{{call {routine}}}"
            call_params = []
            returned = []
        elif isinstance(params, dict):
            placeholders = ", ".join(f":{key}" for key in params.keys())
            sql = f"{{call {routine}({placeholders})}}" if placeholders else f"{{call {routine}}}"
            call_params = params
            returned = params
        else:
            values = list(params)
            placeholders = ", ".join("?" for _ in values)
            sql = f"{{call {routine}({placeholders})}}" if placeholders else f"{{call {routine}}}"
            call_params = values
            returned = values

        try:
            normalized_sql, ordered_params = normalize_callable_query(sql, call_params)
        except ValueError as exc:
            raise errors.ProgrammingError(str(exc)) from exc

        self._reset_state()
        page_size = self.arraysize if self.arraysize and self.arraysize > 1 else 0
        self._stream = self._connection._execute_query(normalized_sql, ordered_params, page_size)
        self._prime_stream_metadata(self._stream)
        self._results = []
        self._pos = 0
        self._update_description(self._stream)
        self.rowcount = -1
        self.lastrowid = None
        self.statusmessage = None
        return returned

    def __iter__(self):
        return self

    def __next__(self):
        row = self.fetchone()
        if row is None:
            raise StopIteration
        return row

    def fetchone(self):
        self._ensure_open()
        if self._pos < len(self._results):
            row = self._results[self._pos]
            self._pos += 1
            return row
        if self._stream is None:
            return None
        row = self._stream.read_row()
        self._update_description(self._stream)
        if row is None:
            if self._stream.rowcount is not None and self._stream.rowcount >= 0:
                self.rowcount = self._stream.rowcount
            self.lastrowid = getattr(self._stream, "lastrowid", None)
            self.statusmessage = getattr(self._stream, "command", None)
            completion_count = getattr(self._stream, "completion_count", 0)
            if completion_count > self._last_completion_count:
                self._last_completion_count = completion_count
                self._capture_generated_key(self.lastrowid)
            return None
        return row

    def fetchmany(self, size: Optional[int] = None) -> List:
        self._ensure_open()
        if size is None:
            size = self.arraysize
        if size <= 0:
            return []
        rows = []
        while len(rows) < size:
            row = self.fetchone()
            if row is None:
                break
            rows.append(row)
        return rows

    def fetchall(self) -> List:
        self._ensure_open()
        rows = []
        while True:
            row = self.fetchone()
            if row is None:
                break
            rows.append(row)
        return rows

    def nextset(self):
        self._ensure_open()
        if self._stream is None:
            return None
        while self._stream.read_row() is not None:
            continue
        if not self._stream.has_next_result_set():
            return None
        if not self._stream.next_result_set():
            return None
        self._results = []
        self._pos = 0
        self.description = None
        self.rowcount = -1
        self.lastrowid = None
        self.statusmessage = None
        return True

    def close(self) -> None:
        self._closed = True

    def get_generated_keys(self) -> GeneratedKeysResultSet:
        self._ensure_open()
        return GeneratedKeysResultSet(self._generated_keys)

    def setinputsizes(self, sizes) -> None:
        self._ensure_open()

    def setoutputsize(self, size, column=None) -> None:
        self._ensure_open()

    def _ensure_open(self) -> None:
        if self._closed:
            raise errors.InterfaceError("cursor is closed")

    def _reset_state(self) -> None:
        self._results = []
        self._pos = 0
        self._stream = None
        self.description = None
        self.rowcount = -1
        self.lastrowid = None
        self.statusmessage = None
        self._generated_keys = []
        self._last_completion_count = 0

    def _update_description(self, stream) -> None:
        if self.description is not None:
            return
        if stream is None or not getattr(stream, "columns", None):
            return
        self.description = [
            (
                col.name,
                col.type_oid,
                None,
                col.type_modifier or None,
                None,
                None,
                col.nullable,
            )
            for col in stream.columns
        ]

    def _prime_stream_metadata(self, stream) -> None:
        if stream is None:
            return
        prime = getattr(stream, "prime_metadata", None)
        if callable(prime):
            prime()

    def _drain_stream(self, stream):
        count = stream.rowcount
        while True:
            row = stream.read_row()
            if row is None:
                break
        self.lastrowid = getattr(stream, "lastrowid", None)
        self.statusmessage = getattr(stream, "command", None)
        self._capture_generated_key(self.lastrowid)
        return stream.rowcount if stream.rowcount is not None else count

    def _capture_generated_key(self, key) -> None:
        if key is None:
            return
        try:
            normalized = int(key)
        except (TypeError, ValueError):
            return
        self._generated_keys.append((normalized,))

    @property
    def connection(self):
        return self._connection
