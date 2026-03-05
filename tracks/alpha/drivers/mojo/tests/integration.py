from __future__ import annotations

import os
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / "src"))

import scratchbird


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
    dsn = os.environ.get("SCRATCHBIRD_MOJO_URL", "")
    if dsn:
        _run_smoke_for_dsn(dsn, "direct integration")
    else:
        print("SCRATCHBIRD_MOJO_URL not set; skipping Mojo direct integration smoke.")

    manager_dsn = os.environ.get("SCRATCHBIRD_MOJO_MANAGER_URL", "")
    if manager_dsn:
        _run_smoke_for_dsn(manager_dsn, "manager-proxy integration")
    else:
        print("SCRATCHBIRD_MOJO_MANAGER_URL not set; skipping Mojo manager-proxy smoke.")

    bad_auth_dsn = os.environ.get("SCRATCHBIRD_MOJO_BAD_AUTH_URL", "")
    if bad_auth_dsn:
        _expect_auth_failure(bad_auth_dsn)
    else:
        print("SCRATCHBIRD_MOJO_BAD_AUTH_URL not set; skipping Mojo bad-auth smoke.")


if __name__ == "__main__":
    main()
