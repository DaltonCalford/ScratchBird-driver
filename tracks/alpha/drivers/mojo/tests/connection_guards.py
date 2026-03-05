from __future__ import annotations

import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / "src"))

import scratchbird


def _require(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def _assert_connect_guard(dsn: str, expected_message_fragment: str) -> None:
    cfg = scratchbird.ScratchBirdConfig(dsn)
    try:
        scratchbird.connect(cfg)
        raise RuntimeError("expected connect guard to reject DSN")
    except Exception as exc:
        _require(
            expected_message_fragment in str(exc),
            f"expected guard message containing '{expected_message_fragment}', got '{exc}'",
        )


def main() -> None:
    _assert_connect_guard(
        "scratchbird://user:pass@localhost:3092/testdb?sslmode=disable",
        "TLS is required for ScratchBird connections",
    )
    _assert_connect_guard(
        "scratchbird://user:pass@localhost:3092/testdb?binary_transfer=false",
        "binary_transfer=false is not supported",
    )
    _assert_connect_guard(
        "scratchbird://user:pass@localhost:3092/testdb?compression=zstd",
        "compression=zstd is not supported",
    )
    print("Mojo connection guard tests OK")


if __name__ == "__main__":
    main()
