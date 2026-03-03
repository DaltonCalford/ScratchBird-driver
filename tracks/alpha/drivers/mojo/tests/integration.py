from __future__ import annotations

import os
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / "src"))

import scratchbird


def main() -> None:
    dsn = os.environ.get("SCRATCHBIRD_MOJO_URL", "")
    if not dsn:
        print("SCRATCHBIRD_MOJO_URL not set; skipping Mojo integration smoke.")
        return

    cfg = scratchbird.ScratchBirdConfig(dsn)
    conn = scratchbird.connect(cfg)
    try:
        res = conn.query("SELECT 1")
        if len(res.rows) == 0 or res.rows[0][0] != 1:
            raise RuntimeError("unexpected SELECT 1 result")

        res = conn.query("SELECT * FROM type_coverage")
        if len(res.rows) == 0:
            raise RuntimeError("type_coverage returned no rows")

        print("Mojo integration smoke OK")
    finally:
        conn.close()


if __name__ == "__main__":
    main()
