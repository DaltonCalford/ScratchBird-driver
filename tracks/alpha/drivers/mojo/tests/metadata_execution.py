from __future__ import annotations

import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / "src"))

import scratchbird


def _require(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


class QueryHarness:
    def __init__(self):
        self.calls = []
        self.result = scratchbird.ScratchBirdResult([[1]], [], 1)

    def _begin_operation(self, name: str, sql: str):
        self.calls.append(("begin", name, sql))
        return None

    def _end_operation(self, span, success: bool):
        self.calls.append(("end", success))

    def _extended_query(self, sql: str, params):
        self.calls.append(("extended", sql, list(params)))
        return self.result

    def _send_message(self, msg_type: int, payload: bytes, flags: int = 0, force_zero: bool = False):
        self.calls.append(("send", msg_type, payload))

    def _read_resultset(self):
        self.calls.append(("read",))
        return self.result


def test_normalize_metadata_collection_aliases() -> None:
    _require(scratchbird.normalize_metadata_collection_name("catalog") == "catalogs", "catalog alias mismatch")
    _require(scratchbird.normalize_metadata_collection_name("primaryKeys") == "primary_keys", "primary key alias mismatch")
    _require(scratchbird.normalize_metadata_collection_name("foreign-keys") == "foreign_keys", "foreign key alias mismatch")
    _require(
        scratchbird.normalize_metadata_collection_name("table privileges") == "table_privileges",
        "table privileges alias mismatch",
    )
    _require(
        scratchbird.normalize_metadata_collection_name("columnprivilege") == "column_privileges",
        "column privileges alias mismatch",
    )
    _require(scratchbird.normalize_metadata_collection_name("typeinfo") == "type_info", "type info alias mismatch")


def test_resolve_metadata_collection_query_extended_families() -> None:
    _require(
        scratchbird.resolve_metadata_collection_query("catalogs") == scratchbird.METADATA_CATALOGS_QUERY,
        "catalog query mismatch",
    )
    _require(
        scratchbird.resolve_metadata_collection_query("primarykeys") == scratchbird.METADATA_PRIMARY_KEYS_QUERY,
        "primary keys query mismatch",
    )
    _require(
        scratchbird.resolve_metadata_collection_query("foreign_keys") == scratchbird.METADATA_FOREIGN_KEYS_QUERY,
        "foreign keys query mismatch",
    )
    _require(
        scratchbird.resolve_metadata_collection_query("tableprivileges")
        == scratchbird.METADATA_TABLE_PRIVILEGES_QUERY,
        "table privileges query mismatch",
    )
    _require(
        scratchbird.resolve_metadata_collection_query("column_privileges")
        == scratchbird.METADATA_COLUMN_PRIVILEGES_QUERY,
        "column privileges query mismatch",
    )
    _require(
        scratchbird.resolve_metadata_collection_query("type_info") == scratchbird.METADATA_TYPE_INFO_QUERY,
        "type info query mismatch",
    )


def test_query_metadata_routes_through_query_path() -> None:
    conn = QueryHarness()
    result = scratchbird.ScratchBirdConnection.query_metadata(conn, "primarykeys")
    _require(result is conn.result, "query_metadata should return harness result")
    _require(
        any(call[0] == "send" and call[1] == scratchbird.MessageType.QUERY for call in conn.calls),
        "query path should send QUERY",
    )
    _require(("read",) in conn.calls, "query path should read resultset")

    sent_payload = None
    for call in conn.calls:
        if call[0] == "send" and call[1] == scratchbird.MessageType.QUERY:
            sent_payload = call[2]
            break
    _require(sent_payload is not None, "query_metadata should send QUERY payload")
    _require(
        sent_payload.decode("utf-8") == scratchbird.METADATA_PRIMARY_KEYS_QUERY,
        "query_metadata should route primary key query SQL",
    )


def test_get_schema_returns_result_rows() -> None:
    conn = QueryHarness()
    conn.result = scratchbird.ScratchBirdResult([[7], [9]], [], 2)
    rows = scratchbird.ScratchBirdConnection.get_schema(conn, "catalog")
    _require(rows == [[7], [9]], "get_schema should return result rows")


def test_query_metadata_rejects_unsupported_collection() -> None:
    conn = QueryHarness()
    try:
        scratchbird.ScratchBirdConnection.query_metadata(conn, "unsupported_collection")
        raise RuntimeError("expected unsupported collection failure")
    except scratchbird.ScratchBirdError as exc:
        _require(exc.sqlstate == "0A000", "unsupported collection should map to 0A000")


def main() -> None:
    test_normalize_metadata_collection_aliases()
    test_resolve_metadata_collection_query_extended_families()
    test_query_metadata_routes_through_query_path()
    test_get_schema_returns_result_rows()
    test_query_metadata_rejects_unsupported_collection()
    print("Mojo metadata execution tests OK")


if __name__ == "__main__":
    main()
