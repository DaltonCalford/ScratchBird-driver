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


def _assert_connect_guard_sqlstate(dsn: str, expected_sqlstate: str) -> None:
    cfg = scratchbird.ScratchBirdConfig(dsn)
    try:
        scratchbird.connect(cfg)
        raise RuntimeError("expected connect guard to reject DSN")
    except Exception as exc:
        actual = str(getattr(exc, "sqlstate", "") or "")
        _require(
            actual == expected_sqlstate,
            f"expected sqlstate '{expected_sqlstate}', got '{actual}'",
        )


def _assert_connect_ok(dsn: str) -> None:
    cfg = scratchbird.ScratchBirdConfig(dsn)
    conn = scratchbird.connect(cfg)
    conn.close()


def main() -> None:
    _assert_connect_guard(
        "scratchbird://user:pass@localhost:3092/testdb?sslmode=disable",
        "TLS is required for ScratchBird connections",
    )
    _assert_connect_ok(
        "scratchbird://user:pass@localhost:3092/testdb?binary_transfer=false",
    )
    _assert_connect_ok(
        "scratchbird://user:pass@localhost:3092/testdb?binarytransfer=false",
    )
    _assert_connect_ok(
        "scratchbird://user:pass@localhost:3092/testdb?compression=zstd",
    )
    _assert_connect_ok(
        "scratchbird://user:pass@localhost:3092/testdb?compression=none",
    )
    _assert_connect_guard(
        "scratchbird://user:pass@localhost:3092/testdb?compression=gzip",
        "compression must be one of off,zstd,none",
    )
    _assert_connect_guard(
        "scratchbird://user:pass@localhost:3092/testdb?front_door_mode=invalid",
        "front_door_mode must be direct or manager_proxy.",
    )
    _assert_connect_ok(
        "scratchbird://user:pass@localhost:3092/testdb?protocol=scratchbird-native",
    )
    _assert_connect_ok(
        "scratchbird://user:pass@localhost:3092/testdb?parser=scratchbird_native",
    )
    _assert_connect_guard_sqlstate(
        "scratchbird://user:pass@localhost:3092/testdb?dialect=postgres",
        "0A000",
    )
    _assert_connect_guard_sqlstate(
        "scratchbird://:pass@localhost:3092/testdb?sslmode=require",
        "28000",
    )
    _assert_connect_guard_sqlstate(
        "scratchbird://user:pass@localhost:3092/?sslmode=require",
        "28000",
    )
    _assert_connect_ok(
        "scratchbird://user:pass@/testdb?sslmode=require",
    )
    _assert_connect_guard_sqlstate(
        "scratchbird://user:pass@localhost:3092/testdb?host=",
        "28000",
    )
    _assert_connect_guard_sqlstate(
        "scratchbird://user:pass@localhost:3092/testdb?note=%ZZ",
        "22023",
    )
    _assert_connect_guard_sqlstate(
        "scratchbird://user:pass@[::1:3092/testdb?sslmode=require",
        "22023",
    )
    _assert_connect_guard_sqlstate(
        "scratchbird://user:pass@localhost:3092/testdb?front_door_mode=managerproxy",
        "08001",
    )
    _assert_connect_guard_sqlstate(
        "scratchbird://user:pass@localhost:3092/testdb?front_door_mode=direct&connection_mode=managerproxy",
        "08001",
    )
    _assert_connect_ok(
        "scratchbird://user:pass@localhost:3092/testdb?front_door_mode=managerproxy&manager_auth_token=token",
    )
    _assert_connect_guard_sqlstate(
        "scratchbird://user:pass@localhost:3092/testdb?min_pool_size=bad",
        "22023",
    )
    _assert_connect_guard_sqlstate(
        "scratchbird://user:pass@localhost:3092/testdb?max_pool_size=0",
        "22023",
    )
    _assert_connect_guard_sqlstate(
        "scratchbird://user:pass@localhost:3092/testdb?min_pool_size=5&max_pool_size=2",
        "22023",
    )
    _assert_connect_guard_sqlstate(
        "scratchbird://user:pass@localhost:3092/testdb?default_row_fetch_size=bad",
        "22023",
    )
    _assert_connect_guard_sqlstate(
        "scratchbird://user:pass@localhost:3092/testdb?default_row_fetch_size=-1",
        "22023",
    )
    _assert_connect_guard_sqlstate(
        "scratchbird://user:pass@localhost:3092/testdb?connection_lifetime=bad",
        "22023",
    )
    _assert_connect_guard_sqlstate(
        "scratchbird://user:pass@localhost:3092/testdb?poolingconnectionlifetime=-1",
        "22023",
    )
    _assert_connect_guard_sqlstate(
        "scratchbird://user:pass@localhost:3092/testdb?manager_client_flags=bad",
        "22023",
    )
    _assert_connect_guard_sqlstate(
        "scratchbird://user:pass@localhost:3092/testdb?mcp_client_flags=-1",
        "22023",
    )
    _assert_connect_guard_sqlstate(
        "scratchbird://user:pass@localhost:3092/testdb?port=bad",
        "22023",
    )
    _assert_connect_guard_sqlstate(
        "scratchbird://user:pass@localhost:3092/testdb?port=0",
        "22023",
    )
    _assert_connect_guard_sqlstate(
        "scratchbird://user:pass@localhost:3092/testdb?pgport=70000",
        "22023",
    )
    _assert_connect_guard_sqlstate(
        "scratchbird://user:pass@localhost:3092/testdb?connect_timeout=bad",
        "22023",
    )
    _assert_connect_guard_sqlstate(
        "scratchbird://user:pass@localhost:3092/testdb?sockettimeout=-1",
        "22023",
    )
    _assert_connect_guard_sqlstate(
        "scratchbird://user:pass@localhost:3092/testdb?pooling_acquire_timeout=-1",
        "22023",
    )
    _assert_connect_guard(
        "scratchbird://user:pass@localhost:3092/testdb?sb_test_auth_fail=true",
        "authentication failed",
    )
    _assert_connect_guard_sqlstate(
        "scratchbird://user:pass@localhost:3092/testdb?sb_test_auth_fail=true",
        "28P01",
    )
    print("Mojo connection guard tests OK")


if __name__ == "__main__":
    main()
