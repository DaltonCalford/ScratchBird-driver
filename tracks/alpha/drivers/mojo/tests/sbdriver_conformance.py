# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

from __future__ import annotations

import json
import os
import pathlib
import shutil
import subprocess
import sys
import urllib.parse

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / "src"))

import scratchbird


class TestSpec:
    def __init__(self):
        self.test_id = ""
        self.kind = ""
        self.sql = ""
        self.expect_rows = -1
        self.expect_sqlstate = ""
        self.cancel_after_rows = 0
        self.requires = []
        self.params = []
        self.dsn_append = ""


def _is_truthy(value: str) -> bool:
    return value.strip().lower() in ("1", "true", "yes", "on")


def _native_bootstrap_command(lane_root: pathlib.Path) -> list[str] | None:
    mojo_bin = os.environ.get("MOJO_BIN", "").strip()
    if mojo_bin:
        return [mojo_bin, "run", "-I", "src", "tests/native_bootstrap.mojo"]

    mojo_path = shutil.which("mojo")
    if mojo_path:
        return [mojo_path, "run", "-I", "src", "tests/native_bootstrap.mojo"]

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
            "tests/native_bootstrap.mojo",
        ]
    return None


def _run_native_bootstrap_smoke(lane_root: pathlib.Path) -> None:
    if _is_truthy(os.environ.get("SCRATCHBIRD_MOJO_SKIP_NATIVE_BOOTSTRAP", "")):
        return

    required = _is_truthy(os.environ.get("SCRATCHBIRD_MOJO_NATIVE_REQUIRED", ""))
    command = _native_bootstrap_command(lane_root)
    if command is None:
        if required:
            raise RuntimeError("Mojo native bootstrap launcher unavailable (no mojo/pixi found).")
        return

    completed = subprocess.run(
        command,
        cwd=lane_root,
        capture_output=True,
        text=True,
        check=False,
    )
    if completed.returncode == 0:
        return

    error_text = (completed.stderr or completed.stdout or "").strip()
    first_line = error_text.splitlines()[0] if error_text else "no details"
    if required:
        raise RuntimeError(
            f"Mojo native bootstrap smoke failed with exit {completed.returncode}: {first_line}"
        )


def _normalize_kind(kind: str) -> str:
    # Conformance manifests use native_* kinds while lane harness uses logical kinds.
    if kind == "native_query":
        return "query"
    if kind == "native_prepare_bind":
        return "prepare_bind"
    return kind


def _json_escape(text: str) -> str:
    return text.replace("\\", "\\\\").replace('"', '\\"')


def _parse_tests(manifest_text: str):
    try:
        payload = json.loads(manifest_text)
    except Exception as exc:
        raise RuntimeError(f"invalid manifest JSON: {exc}") from exc

    tests_raw = payload.get("tests", [])
    if not isinstance(tests_raw, list):
        return []

    tests = []
    for item in tests_raw:
        if not isinstance(item, dict):
            continue
        current = TestSpec()
        current.test_id = str(item.get("id", "") or "").strip()
        current.kind = str(item.get("kind", "") or "").strip()
        current.sql = str(item.get("sql", "") or "").strip()
        current.expect_rows = _coerce_int(item.get("expect_rows"), -1)
        current.expect_sqlstate = str(item.get("expect_sqlstate", "") or "").strip()
        current.cancel_after_rows = _coerce_int(item.get("cancel_after_rows"), 0)
        current.requires = _coerce_string_list(item.get("requires"))
        current.params = _coerce_params(item.get("params"))
        current.dsn_append = str(item.get("dsn_append", "") or "").strip()
        if current.test_id:
            tests.append(current)
    return tests


def _coerce_int(value, default: int) -> int:
    try:
        if value is None:
            return default
        return int(value)
    except Exception:
        return default


def _coerce_string_list(value):
    if not isinstance(value, list):
        return []
    out = []
    for item in value:
        text = str(item or "").strip()
        if text:
            out.append(text)
    return out


def _coerce_params(value):
    if not isinstance(value, list):
        return []
    return value


def _dsn_with_append(base_dsn: str, query_append: str) -> str:
    fragment = (query_append or "").strip()
    if not fragment:
        return base_dsn
    if fragment.startswith("?"):
        fragment = fragment[1:]

    appended_pairs = urllib.parse.parse_qsl(fragment, keep_blank_values=True)
    if not appended_pairs:
        return base_dsn

    parsed = urllib.parse.urlparse(base_dsn)
    existing_pairs = urllib.parse.parse_qsl(parsed.query, keep_blank_values=True)
    merged_query = urllib.parse.urlencode(existing_pairs + appended_pairs)
    return urllib.parse.urlunparse(
        (parsed.scheme, parsed.netloc, parsed.path, parsed.params, merged_query, parsed.fragment)
    )


def _normalize_requirement(requirement: str) -> str:
    return requirement.strip().lower().replace("-", "_").replace(" ", "_")


def _unsupported_requirements(spec: TestSpec, conn, enable_prepare: bool, enable_cancel: bool):
    unsupported = []
    for raw in spec.requires:
        requirement = _normalize_requirement(raw)
        if requirement == "":
            continue
        if requirement in ("tls", "auth", "native_parser", "types"):
            continue
        if requirement in ("prepare_bind", "native_prepare_bind", "prepare"):
            has_prepare = hasattr(conn, "prepare") or hasattr(conn, "query")
            if not (enable_prepare and has_prepare):
                unsupported.append(raw)
            continue
        if requirement in ("cancel", "cancellation"):
            has_cancel = hasattr(conn, "cancel")
            has_stream = hasattr(conn, "stream")
            if not (enable_cancel and has_cancel and has_stream):
                unsupported.append(raw)
            continue
        # Default: keep future manifest requirements safe/explicit.
        unsupported.append(raw)
    return unsupported


def _render_result(test_id: str, status: str, errors):
    escaped = _json_escape(test_id)
    if errors is None:
        errors = []
    err_parts = []
    for err in errors:
        err_parts.append('"' + _json_escape(err) + '"')
    err_json = "[" + ",".join(err_parts) + "]"
    return "{\"test_id\":\"" + escaped + "\",\"status\":\"" + status + "\",\"errors\":" + err_json + "}"


def _matches_expected_sqlstate(exc: Exception, expected_sqlstate: str) -> bool:
    if not expected_sqlstate:
        return False
    actual = str(getattr(exc, "sqlstate", "") or "").strip()
    return actual == expected_sqlstate


def _run_query_tests(tests, dsn: str):
    results = []
    enable_prepare = os.environ.get("SCRATCHBIRD_MOJO_ENABLE_PREPARE_BIND", "1").lower() in ("1", "true", "yes")
    enable_cancel = os.environ.get("SCRATCHBIRD_MOJO_ENABLE_CANCEL", "1").lower() in ("1", "true", "yes")
    if not dsn:
        for spec in tests:
            results.append(_render_result(spec.test_id, "skipped", ["SCRATCHBIRD_MOJO_URL not set"]))
        return results

    conn = None
    conn_dsn = ""
    try:
        def ensure_connection(target_dsn: str):
            nonlocal conn
            nonlocal conn_dsn
            if conn is not None and conn_dsn == target_dsn:
                return conn
            if conn is not None:
                conn.close()
            cfg = scratchbird.ScratchBirdConfig(target_dsn)
            conn = scratchbird.connect(cfg)
            conn_dsn = target_dsn
            return conn

        for spec in tests:
            kind = _normalize_kind(spec.kind)
            test_dsn = _dsn_with_append(dsn, spec.dsn_append)
            try:
                current_conn = ensure_connection(test_dsn)
            except Exception as exc:
                if _matches_expected_sqlstate(exc, spec.expect_sqlstate):
                    results.append(_render_result(spec.test_id, "ok", []))
                else:
                    results.append(_render_result(spec.test_id, "failed", [str(exc)]))
                continue
            unsupported = _unsupported_requirements(spec, current_conn, enable_prepare, enable_cancel)
            if unsupported:
                reasons = "unsupported requires: " + ", ".join(unsupported)
                results.append(_render_result(spec.test_id, "skipped", [reasons]))
                continue
            if kind == "auth":
                # A successful connect already exercises auth negotiation in this harness.
                if spec.expect_sqlstate:
                    results.append(_render_result(spec.test_id, "failed", [f"expected sqlstate {spec.expect_sqlstate}"]))
                else:
                    results.append(_render_result(spec.test_id, "ok", []))
                continue
            if kind == "query":
                if not spec.sql:
                    results.append(_render_result(spec.test_id, "skipped", ["missing sql"]))
                    continue
                try:
                    res = current_conn.query(spec.sql)
                    if spec.expect_sqlstate:
                        results.append(_render_result(spec.test_id, "failed", [f"expected sqlstate {spec.expect_sqlstate}"]))
                    elif spec.expect_rows >= 0 and len(res.rows) != spec.expect_rows:
                        results.append(_render_result(spec.test_id, "failed", ["row count mismatch"]))
                    else:
                        results.append(_render_result(spec.test_id, "ok", []))
                except Exception as exc:
                    if _matches_expected_sqlstate(exc, spec.expect_sqlstate):
                        results.append(_render_result(spec.test_id, "ok", []))
                    else:
                        results.append(_render_result(spec.test_id, "failed", [str(exc)]))
                continue
            if kind == "prepare_bind":
                if not enable_prepare:
                    results.append(_render_result(spec.test_id, "skipped", ["prepare_bind disabled"]))
                    continue
                if not spec.sql:
                    results.append(_render_result(spec.test_id, "skipped", ["missing sql"]))
                    continue
                try:
                    if hasattr(current_conn, "prepare"):
                        stmt = current_conn.prepare(spec.sql)
                        execute = getattr(stmt, "execute", None)
                        if callable(execute):
                            res = execute(spec.params)
                        else:
                            res = current_conn.query(spec.sql, spec.params)
                    else:
                        res = current_conn.query(spec.sql, spec.params)
                    if spec.expect_sqlstate:
                        results.append(_render_result(spec.test_id, "failed", [f"expected sqlstate {spec.expect_sqlstate}"]))
                    elif spec.expect_rows >= 0 and len(res.rows) != spec.expect_rows:
                        results.append(_render_result(spec.test_id, "failed", ["row count mismatch"]))
                    else:
                        results.append(_render_result(spec.test_id, "ok", []))
                except Exception as exc:
                    if _matches_expected_sqlstate(exc, spec.expect_sqlstate):
                        results.append(_render_result(spec.test_id, "ok", []))
                    else:
                        results.append(_render_result(spec.test_id, "failed", [str(exc)]))
                continue
            if kind == "cancel":
                if not enable_cancel:
                    results.append(_render_result(spec.test_id, "skipped", ["cancel disabled"]))
                    continue
                if not hasattr(current_conn, "cancel"):
                    results.append(_render_result(spec.test_id, "failed", ["cancel not implemented"]))
                    continue
                if not spec.sql:
                    results.append(_render_result(spec.test_id, "skipped", ["missing sql"]))
                    continue
                try:
                    stream = current_conn.stream(spec.sql, None, 1)
                    row_budget = spec.cancel_after_rows if spec.cancel_after_rows > 0 else 1
                    for _ in range(row_budget):
                        try:
                            stream.__next__()
                        except StopIteration:
                            break
                    current_conn.cancel()
                    if spec.expect_sqlstate:
                        try:
                            stream.__next__()
                            results.append(
                                _render_result(spec.test_id, "failed", [f"expected sqlstate {spec.expect_sqlstate}"])
                            )
                        except Exception as exc:
                            if _matches_expected_sqlstate(exc, spec.expect_sqlstate):
                                results.append(_render_result(spec.test_id, "ok", []))
                            else:
                                results.append(_render_result(spec.test_id, "failed", [str(exc)]))
                    else:
                        results.append(_render_result(spec.test_id, "ok", []))
                except Exception as exc:
                    if _matches_expected_sqlstate(exc, spec.expect_sqlstate):
                        results.append(_render_result(spec.test_id, "ok", []))
                    else:
                        results.append(_render_result(spec.test_id, "failed", [str(exc)]))
                continue
            results.append(_render_result(spec.test_id, "skipped", ["unsupported kind"]))
    finally:
        if conn is not None:
            conn.close()
    return results


def _manifest_from_args(argv) -> str:
    if "--manifest" not in argv:
        return ""
    idx = argv.index("--manifest")
    if idx + 1 < len(argv):
        return argv[idx + 1]
    return ""


def main() -> None:
    manifest = _manifest_from_args(sys.argv)
    if not manifest:
        manifest = os.environ.get("SCRATCHBIRD_CONFORMANCE_MANIFEST", "")

    if not manifest:
        sys.stdout.write("{\"results\":[],\"status\":\"skipped\",\"errors\":[\"manifest not provided\"]}\n")
        return

    lane_root = pathlib.Path(__file__).resolve().parents[1]
    try:
        _run_native_bootstrap_smoke(lane_root)
    except Exception as exc:
        sys.stdout.write(
            "{\"results\":[],\"status\":\"error\",\"errors\":[\"native bootstrap failed: "
            + _json_escape(str(exc))
            + "\"]}\n"
        )
        return

    try:
        with open(manifest, "r", encoding="utf-8") as handle:
            text = handle.read()
    except Exception:
        sys.stdout.write("{\"results\":[],\"status\":\"error\",\"errors\":[\"failed to read manifest\"]}\n")
        return

    tests = _parse_tests(text)
    dsn = os.environ.get("SCRATCHBIRD_MOJO_URL", "")
    results = _run_query_tests(tests, dsn)
    summary = "[" + ",".join(results) + "]"
    sys.stdout.write("{\"suite\":\"mojo-harness\",\"results\":" + summary + ",\"status\":\"ok\"}\n")


if __name__ == "__main__":
    main()
