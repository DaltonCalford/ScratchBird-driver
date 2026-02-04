# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

import os
import scratchbird


def main():
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
