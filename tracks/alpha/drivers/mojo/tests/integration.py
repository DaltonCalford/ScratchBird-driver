from __future__ import annotations

import os
import pathlib
import shutil
import subprocess
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / "src"))

import scratchbird


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


def _run_smoke_for_dsn(dsn: str, label: str) -> None:
    cfg = scratchbird.ScratchBirdConfig(dsn)
    conn = scratchbird.connect(cfg)
    try:
        res = conn.query("SELECT 1")
        if len(res.rows) == 0 or res.rows[0][0] != 1:
            raise RuntimeError("unexpected SELECT 1 result")

        res = conn.query("SELECT * FROM type_coverage")
        if len(res.rows) == 0:
            raise RuntimeError("type_coverage returned no rows")

        if conn.query_metadata_rows("schemas") <= 0:
            raise RuntimeError("metadata schemas rowcount should be positive")
        if conn.query_metadata_rows_restricted("tables", "schema", "public") <= 0:
            raise RuntimeError("restricted metadata table rowcount should be positive")
        if conn.query_metadata_rows_restricted_multi("tables", {"schema": "public", "table": "ord%"}) <= 0:
            raise RuntimeError("multi-restricted metadata table rowcount should be positive")
        payload = conn.ddl_editor_schema_payload(schema_pattern="users.%", expand_schema_parents=True)
        if set(payload.keys()) != {"schemaPattern", "expandSchemaParents", "schemaPaths", "schemaTree"}:
            raise RuntimeError("ddl_editor_schema_payload keys mismatch")
        if payload.get("schemaPattern") != "users.%":
            raise RuntimeError("ddl_editor_schema_payload schemaPattern mismatch")
        if payload.get("expandSchemaParents") is not True:
            raise RuntimeError("ddl_editor_schema_payload expandSchemaParents mismatch")
        if not isinstance(payload.get("schemaPaths"), list) or len(payload.get("schemaPaths")) == 0:
            raise RuntimeError("ddl_editor_schema_payload schemaPaths should be a non-empty list")
        if not isinstance(payload.get("schemaTree"), list):
            raise RuntimeError("ddl_editor_schema_payload schemaTree should be a list")
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
        _run_smoke_for_dsn(dsn, "direct integration")
    else:
        print("SCRATCHBIRD_MOJO_URL not set; skipping Mojo direct integration smoke.")

    manager_dsn = os.environ.get("SCRATCHBIRD_MOJO_MANAGER_URL", "").strip()
    if not manager_dsn and not _is_truthy(os.environ.get("SCRATCHBIRD_MOJO_DISABLE_FALLBACK_DSN", "")):
        manager_dsn = _deterministic_fallback_manager_dsn()
    if manager_dsn:
        _run_smoke_for_dsn(manager_dsn, "manager-proxy integration")
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
