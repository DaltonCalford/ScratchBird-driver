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


def test_normalize_metadata_restriction_aliases() -> None:
    _require(scratchbird.normalize_metadata_restriction_key("TABLE_SCHEM") == "schema_name", "schema alias mismatch")
    _require(scratchbird.normalize_metadata_restriction_key("column") == "column_name", "column alias mismatch")
    _require(scratchbird.normalize_metadata_restriction_key("none") == "", "none restriction should normalize empty")
    try:
        scratchbird.normalize_metadata_restriction_key("unsupported_restriction")
        raise RuntimeError("expected unsupported restriction failure")
    except scratchbird.ScratchBirdError as exc:
        _require(exc.sqlstate == "0A000", "unsupported restriction should map to 0A000")


def test_resolve_metadata_collection_query_restricted() -> None:
    _require(
        scratchbird.resolve_metadata_collection_query_restricted("table", "name", "orders")
        == "SELECT table_id, schema_id, table_name, table_type, owner_id FROM sys.tables WHERE is_valid = 1 AND table_name = 'orders' ORDER BY table_name",
        "restricted table query mismatch",
    )
    _require(
        "schema_name = 'acme''schema'"
        in scratchbird.resolve_metadata_collection_query_restricted("schema", "schema", "acme'schema"),
        "restricted schema query should escape SQL literals",
    )
    _require(
        scratchbird.resolve_metadata_collection_query_restricted("tables", "table_name", "")
        == scratchbird.METADATA_TABLES_QUERY,
        "empty restriction value should not mutate query",
    )
    try:
        scratchbird.resolve_metadata_collection_query_restricted("tables", "schema", "public")
        raise RuntimeError("expected unsupported collection restriction failure")
    except scratchbird.ScratchBirdError as exc:
        _require(exc.sqlstate == "0A000", "unsupported collection restriction should map to 0A000")


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


def test_query_metadata_restricted_routes_through_query_path() -> None:
    conn = QueryHarness()
    result = scratchbird.ScratchBirdConnection.query_metadata_restricted(conn, "table", "name", "orders")
    _require(result is conn.result, "query_metadata_restricted should return harness result")
    sent_payload = None
    for call in conn.calls:
        if call[0] == "send" and call[1] == scratchbird.MessageType.QUERY:
            sent_payload = call[2]
            break
    _require(sent_payload is not None, "query_metadata_restricted should send QUERY payload")
    _require(
        sent_payload.decode("utf-8")
        == "SELECT table_id, schema_id, table_name, table_type, owner_id FROM sys.tables WHERE is_valid = 1 AND table_name = 'orders' ORDER BY table_name",
        "query_metadata_restricted should route restricted query SQL",
    )


def test_get_schema_returns_result_rows() -> None:
    conn = QueryHarness()
    conn.result = scratchbird.ScratchBirdResult([[7], [9]], [], 2)
    rows = scratchbird.ScratchBirdConnection.get_schema(conn, "catalog")
    _require(rows == [[7], [9]], "get_schema should return result rows")


def test_query_metadata_rows_returns_rowcount() -> None:
    conn = QueryHarness()
    conn.result = scratchbird.ScratchBirdResult([[1], [2], [3]], [], 3)
    rowcount = scratchbird.ScratchBirdConnection.query_metadata_rows(conn, "table")
    _require(rowcount == 3, "query_metadata_rows should return result rowcount")


def test_query_metadata_rows_restricted_returns_rowcount() -> None:
    conn = QueryHarness()
    conn.result = scratchbird.ScratchBirdResult([[1], [2], [3], [4]], [], 4)
    rowcount = scratchbird.ScratchBirdConnection.query_metadata_rows_restricted(
        conn,
        "table",
        "name",
        "orders",
    )
    _require(rowcount == 4, "query_metadata_rows_restricted should return result rowcount")


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
    test_normalize_metadata_restriction_aliases()
    test_resolve_metadata_collection_query_restricted()
    test_query_metadata_routes_through_query_path()
    test_query_metadata_restricted_routes_through_query_path()
    test_get_schema_returns_result_rows()
    test_query_metadata_rows_returns_rowcount()
    test_query_metadata_rows_restricted_returns_rowcount()
    test_query_metadata_rejects_unsupported_collection()
    print("Mojo metadata execution tests OK")


if __name__ == "__main__":
    main()
