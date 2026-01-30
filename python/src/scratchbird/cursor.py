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

    def execute(self, sql: str, params=None) -> None:
        self._ensure_open()
        if sql is None:
            raise errors.ProgrammingError("sql is required")
        self._reset_state()
        page_size = self.arraysize if self.arraysize and self.arraysize > 1 else 0
        self._stream = self._connection._execute_query(sql, params, page_size)
        self._results = []
        self._pos = 0
        self.description = None
        self.rowcount = -1

    def executemany(self, sql: str, seq_of_params: Iterable) -> None:
        self._ensure_open()
        if sql is None:
            raise errors.ProgrammingError("sql is required")
        self._reset_state()
        total = 0
        rowcount_known = True
        page_size = self.arraysize if self.arraysize and self.arraysize > 1 else 0
        for params in seq_of_params:
            stream = self._connection._execute_query(sql, params, page_size)
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

    def close(self) -> None:
        self._closed = True

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

    def _drain_stream(self, stream):
        count = stream.rowcount
        while True:
            row = stream.read_row()
            if row is None:
                break
        return stream.rowcount if stream.rowcount is not None else count

    @property
    def connection(self):
        return self._connection
