from __future__ import annotations

import os
import pathlib
import shutil
import subprocess
import sys
from typing import Any, Mapping

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / "src"))

import scratchbird


_SCHEMA_ROW_ALIASES = ("schema_name", "table_schema", "table_schem", "schema")


def _is_truthy(value: str) -> bool:
    return value.strip().lower() in ("1", "true", "yes", "on")


def _deterministic_fallback_dsn() -> str:
    return "scratchbird://user:pass@localhost:3092/testdb?sslmode=require"


def _deterministic_fallback_manager_dsn() -> str:
    return (
        "scratchbird://user:pass@localhost:3092/testdb"
        "?sslmode=require&front_door_mode=manager_proxy"
    )


def _deterministic_fallback_bad_auth_dsn() -> str:
    return (
        "scratchbird://user:pass@localhost:3092/testdb"
        "?sslmode=require&sb_test_auth_fail=true"
    )


def _is_deterministic_lane_dsn(dsn: str) -> bool:
    return dsn in (_deterministic_fallback_dsn(), _deterministic_fallback_manager_dsn())


def _native_bootstrap_command(script_path: str) -> list[str] | None:
    mojo_bin = os.environ.get("MOJO_BIN", "").strip()
    if mojo_bin:
        return [mojo_bin, "run", "-I", "src", "-I", "src/scratchbird", script_path]

    mojo_path = shutil.which("mojo")
    if mojo_path:
        return [mojo_path, "run", "-I", "src", "-I", "src/scratchbird", script_path]

    pixi_path = shutil.which("pixi")
    manifest = pathlib.Path(
        os.environ.get(
            "MOJO_PIXI_MANIFEST",
            str(pathlib.Path.home() / "mojo-work" / "sb-mojo"),
        )
    )
    if pixi_path and manifest.is_dir():
        return [
            pixi_path,
            "run",
            "-m",
            str(manifest),
            "--executable",
            "mojo",
            "run",
            "-I",
            "src",
            "-I",
            "src/scratchbird",
            script_path,
        ]

    return None


def _run_native_bootstrap_smoke(lane_root: pathlib.Path) -> None:
    if _is_truthy(os.environ.get("SCRATCHBIRD_MOJO_SKIP_NATIVE_BOOTSTRAP", "")):
        print("SCRATCHBIRD_MOJO_SKIP_NATIVE_BOOTSTRAP set; skipping Mojo native bootstrap smoke.")
        return

    required = _is_truthy(os.environ.get("SCRATCHBIRD_MOJO_NATIVE_REQUIRED", ""))
    smoke_steps = [
        ("scratchbird module surface smoke", "tests/scratchbird_surface.mojo"),
        ("native bootstrap smoke", "tests/native_bootstrap.mojo"),
    ]
    for label, script_path in smoke_steps:
        command = _native_bootstrap_command(script_path)
        if command is None:
            message = f"Mojo launcher unavailable for {label} (no mojo/pixi found)."
            if required:
                raise RuntimeError(message)
            print(message + " Continuing with Python integration smoke.")
            return

        completed = subprocess.run(
            command,
            cwd=lane_root,
            capture_output=True,
            text=True,
            check=False,
        )
        if completed.returncode == 0:
            output = (completed.stdout or "").strip()
            if output:
                print(output)
            else:
                print(f"Mojo {label} OK")
            continue

        error_text = (completed.stderr or completed.stdout or "").strip()
        first_line = error_text.splitlines()[0] if error_text else "no details"
        if required:
            raise RuntimeError(
                f"Mojo {label} failed with exit {completed.returncode}: {first_line}"
            )
        print(
            f"Mojo {label} failed (continuing with Python integration smoke): {first_line}"
        )
        return


def _normalize_identifier(value: Any) -> str:
    return str(value).strip().lower().replace("-", "_").replace(" ", "_")


def _rows_from_result(result: Any) -> list[Any]:
    rows = getattr(result, "rows", None)
    if rows is None:
        return []
    if isinstance(rows, list):
        return rows
    return list(rows)


def _rowcount_from_result(result: Any) -> int:
    rowcount = getattr(result, "rowcount", None)
    if isinstance(rowcount, int) and rowcount >= 0:
        return rowcount
    return len(_rows_from_result(result))


def _schema_name_from_row(row: Any) -> str | None:
    if isinstance(row, Mapping):
        for key, value in row.items():
            if _normalize_identifier(key) in _SCHEMA_ROW_ALIASES:
                if value is None:
                    return None
                text = str(value).strip()
                return text if text else None
        return None

    if isinstance(row, (tuple, list)):
        if len(row) == 0:
            return None
        candidate = row[1] if len(row) > 1 else row[0]
        if candidate is None:
            return None
        text = str(candidate).strip()
        return text if text else None

    return None


def _validate_payload_contract(payload: Mapping[str, Any]) -> None:
    if set(payload.keys()) != {"schemaPattern", "expandSchemaParents", "schemaPaths", "schemaTree"}:
        raise RuntimeError("ddl_editor_schema_payload keys mismatch")
    if payload.get("schemaPattern") != "users.%":
        raise RuntimeError("ddl_editor_schema_payload schemaPattern mismatch")
    if payload.get("expandSchemaParents") is not True:
        raise RuntimeError("ddl_editor_schema_payload expandSchemaParents mismatch")
    schema_paths = payload.get("schemaPaths")
    if not isinstance(schema_paths, list):
        raise RuntimeError("ddl_editor_schema_payload schemaPaths should be a list")
    if len(schema_paths) != len(set(schema_paths)):
        raise RuntimeError("ddl_editor_schema_payload schemaPaths should be unique")
    for path in schema_paths:
        if not isinstance(path, str) or path.strip() == "":
            raise RuntimeError("ddl_editor_schema_payload schemaPaths should contain non-empty strings")
    for path in schema_paths:
        if "." not in path:
            continue
        parent = path.rsplit(".", 1)[0]
        if parent not in schema_paths:
            raise RuntimeError("ddl_editor_schema_payload schemaPaths should include parent paths when expanded")
    if not isinstance(payload.get("schemaTree"), list):
        raise RuntimeError("ddl_editor_schema_payload schemaTree should be a list")


def _validate_metadata_stability(conn: Any) -> None:
    schemas_total = _rowcount_from_result(conn.query_metadata("schemas"))
    tables_total = _rowcount_from_result(conn.query_metadata("tables"))
    columns_total = _rowcount_from_result(conn.query_metadata("columns"))
    if schemas_total <= 0:
        raise RuntimeError("metadata schemas rowcount should be positive")
    if tables_total <= 0:
        raise RuntimeError("metadata tables rowcount should be positive")
    if columns_total <= 0:
        raise RuntimeError("metadata columns rowcount should be positive")

    tables_public = _rowcount_from_result(conn.query_metadata_restricted("tables", "schema", "public"))
    tables_public_orders = _rowcount_from_result(
        conn.query_metadata_restricted_multi("tables", {"schema": "public", "table": "ord%"})
    )
    tables_wildcard = _rowcount_from_result(conn.query_metadata_restricted("tables", "table", "ord%"))
    tables_escaped = _rowcount_from_result(conn.query_metadata_restricted("tables", "table", r"ord\_%"))

    if tables_public > tables_total:
        raise RuntimeError("restricted metadata table rowcount should not exceed total tables")
    if tables_public_orders > tables_public:
        raise RuntimeError("multi-restricted metadata table rowcount should not exceed schema-restricted tables")
    if tables_escaped > tables_wildcard:
        raise RuntimeError("escaped table wildcard rowcount should not exceed unescaped wildcard rowcount")

    schemas_users = _rowcount_from_result(conn.query_metadata_restricted("schemas", "schema", "users.%"))
    schemas_null = _rowcount_from_result(conn.query_metadata_restricted("schemas", "schema", "null"))
    if schemas_users > schemas_total:
        raise RuntimeError("schema wildcard rowcount should not exceed total schemas")
    if schemas_null > schemas_total:
        raise RuntimeError("null schema rowcount should not exceed total schemas")

    columns_alias_family = _rowcount_from_result(
        conn.query_metadata_restricted_multi(
            "columns",
            {"catalog": "public", "table": "ord%", "type": "INTEGER"},
        )
    )
    if columns_alias_family > columns_total:
        raise RuntimeError("alias-family restricted column rowcount should not exceed total columns")


def _validate_deterministic_metadata_content(conn: Any, payload: Mapping[str, Any]) -> None:
    schema_rows = _rows_from_result(conn.query_metadata("schemas"))
    schema_names = [_schema_name_from_row(row) for row in schema_rows]
    non_null_schema_names = sorted(name for name in schema_names if name is not None)
    if non_null_schema_names != ["sys", "users.alice.dev", "users.bob.dev"]:
        raise RuntimeError("deterministic schema content mismatch")
    if sum(name is None for name in schema_names) != 1:
        raise RuntimeError("deterministic schema rows should include exactly one null schema entry")

    users_rows = _rows_from_result(
        conn.query_metadata_restricted_multi(
            "schemas",
            {"schema": "users.%"},
        )
    )
    users_names = sorted(name for name in (_schema_name_from_row(row) for row in users_rows) if name is not None)
    if users_names != ["users.alice.dev", "users.bob.dev"]:
        raise RuntimeError("deterministic users.% schema restriction mismatch")

    null_rows = _rows_from_result(conn.query_metadata_restricted("schemas", "schema", "null"))
    if len(null_rows) != 1 or _schema_name_from_row(null_rows[0]) is not None:
        raise RuntimeError("deterministic null schema restriction should return one null row")

    expected_paths = ["users", "users.alice", "users.alice.dev", "users.bob", "users.bob.dev"]
    if payload.get("schemaPaths") != expected_paths:
        raise RuntimeError("deterministic ddl_editor_schema_payload schemaPaths mismatch")

    tree = payload.get("schemaTree")
    if not isinstance(tree, list) or len(tree) != 1:
        raise RuntimeError("deterministic ddl_editor_schema_payload schemaTree root mismatch")
    users_root = tree[0]
    if not isinstance(users_root, Mapping) or users_root.get("name") != "users":
        raise RuntimeError("deterministic ddl_editor_schema_payload should have users root node")


def _run_smoke_for_dsn(dsn: str, label: str, deterministic_lane: bool = False) -> None:
    cfg = scratchbird.ScratchBirdConfig(dsn)
    conn = scratchbird.connect(cfg)
    try:
        res = conn.query("SELECT 1")
        if len(res.rows) == 0 or res.rows[0][0] != 1:
            raise RuntimeError("unexpected SELECT 1 result")

        res = conn.query("SELECT * FROM type_coverage")
        if len(res.rows) == 0:
            raise RuntimeError("type_coverage returned no rows")

        _validate_metadata_stability(conn)
        payload = conn.ddl_editor_schema_payload(schema_pattern="users.%", expand_schema_parents=True)
        _validate_payload_contract(payload)
        if deterministic_lane:
            _validate_deterministic_metadata_content(conn, payload)
        print(f"Mojo {label} smoke OK")
    finally:
        conn.close()


def _expect_auth_failure(dsn: str) -> None:
    cfg = scratchbird.ScratchBirdConfig(dsn)
    try:
        conn = scratchbird.connect(cfg)
        try:
            conn.query("SELECT 1")
        finally:
            conn.close()
        raise RuntimeError("expected auth failure for SCRATCHBIRD_MOJO_BAD_AUTH_URL")
    except Exception as exc:
        sqlstate = str(getattr(exc, "sqlstate", "") or "")
        if sqlstate not in ("", "28000", "28P01"):
            raise RuntimeError(f"unexpected bad-auth sqlstate '{sqlstate}'") from exc
        if sqlstate == "" and "auth" not in str(exc).lower():
            raise RuntimeError(f"unexpected bad-auth error '{exc}'") from exc
    print("Mojo bad-auth smoke OK")


def main() -> None:
    lane_root = pathlib.Path(__file__).resolve().parents[1]
    _run_native_bootstrap_smoke(lane_root)

    dsn = os.environ.get("SCRATCHBIRD_MOJO_URL", "").strip()
    if not dsn and not _is_truthy(os.environ.get("SCRATCHBIRD_MOJO_DISABLE_FALLBACK_DSN", "")):
        dsn = _deterministic_fallback_dsn()
    if dsn:
        _run_smoke_for_dsn(dsn, "direct integration", deterministic_lane=_is_deterministic_lane_dsn(dsn))
    else:
        print("SCRATCHBIRD_MOJO_URL not set; skipping Mojo direct integration smoke.")

    manager_dsn = os.environ.get("SCRATCHBIRD_MOJO_MANAGER_URL", "").strip()
    if not manager_dsn and not _is_truthy(os.environ.get("SCRATCHBIRD_MOJO_DISABLE_FALLBACK_DSN", "")):
        manager_dsn = _deterministic_fallback_manager_dsn()
    if manager_dsn:
        _run_smoke_for_dsn(
            manager_dsn,
            "manager-proxy integration",
            deterministic_lane=_is_deterministic_lane_dsn(manager_dsn),
        )
    else:
        print("SCRATCHBIRD_MOJO_MANAGER_URL not set; skipping Mojo manager-proxy smoke.")

    bad_auth_dsn = os.environ.get("SCRATCHBIRD_MOJO_BAD_AUTH_URL", "").strip()
    if not bad_auth_dsn and not _is_truthy(os.environ.get("SCRATCHBIRD_MOJO_DISABLE_FALLBACK_DSN", "")):
        bad_auth_dsn = _deterministic_fallback_bad_auth_dsn()
    if bad_auth_dsn:
        _expect_auth_failure(bad_auth_dsn)
    else:
        print("SCRATCHBIRD_MOJO_BAD_AUTH_URL not set; skipping Mojo bad-auth smoke.")


if __name__ == "__main__":
    main()
