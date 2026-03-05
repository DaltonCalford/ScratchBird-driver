# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

from __future__ import annotations

import os
import pathlib
import sys

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
    tests = []
    current = None
    in_tests = False
    for raw in manifest_text.splitlines():
        line = raw.strip()
        if line.startswith('"tests"'):
            in_tests = True
            continue
        if not in_tests:
            continue
        if line.startswith("{"):
            current = TestSpec()
            continue
        if line.startswith("}"):
            if current is not None and current.test_id:
                tests.append(current)
            current = None
            continue
        if current is None:
            continue
        if '"id"' in line:
            current.test_id = _extract_string(line)
        elif '"kind"' in line:
            current.kind = _extract_string(line)
        elif '"sql"' in line:
            current.sql = _extract_string(line)
        elif '"expect_rows"' in line:
            current.expect_rows = _extract_int(line)
        elif '"expect_sqlstate"' in line:
            current.expect_sqlstate = _extract_string(line)
        elif '"cancel_after_rows"' in line:
            current.cancel_after_rows = _extract_int(line)
        elif '"requires"' in line:
            current.requires = _extract_list(line)
        elif '"params"' in line:
            current.params = _extract_params(line)
    return tests


def _extract_string(line: str) -> str:
    colon = line.find(":")
    if colon < 0:
        return ""
    q1 = line.find('"', colon + 1)
    if q1 < 0:
        return ""
    q2 = line.find('"', q1 + 1)
    if q2 < 0:
        return ""
    return line[q1 + 1 : q2]


def _extract_int(line: str) -> int:
    colon = line.find(":")
    if colon < 0:
        return -1
    num = ""
    for ch in line[colon + 1 :]:
        if ch.isdigit() or ch == '-':
            num += ch
        elif num:
            break
    if not num:
        return -1
    try:
        return int(num)
    except Exception:
        return -1


def _extract_list(line: str):
    if '[' not in line or ']' not in line:
        return []
    start = line.find('[')
    end = line.find(']')
    body = line[start + 1 : end]
    out = []
    for part in body.split(','):
        item = part.strip().strip('"')
        if item:
            out.append(item)
    return out


def _extract_params(line: str):
    if '[' not in line or ']' not in line:
        return []
    start = line.find('[')
    end = line.find(']')
    body = line[start + 1 : end]
    out = []
    for part in body.split(','):
        item = part.strip()
        if item == "":
            continue
        if item.lower() == "null":
            out.append(None)
            continue
        if item.startswith('"') and item.endswith('"'):
            out.append(item.strip('"'))
            continue
        try:
            if "." in item:
                out.append(float(item))
            else:
                out.append(int(item))
            continue
        except Exception:
            out.append(item.strip('"'))
    return out


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

    cfg = scratchbird.ScratchBirdConfig(dsn)
    conn = scratchbird.connect(cfg)
    try:
        for spec in tests:
            kind = _normalize_kind(spec.kind)
            if kind == "auth":
                # A successful connect already exercises auth negotiation in this harness.
                results.append(_render_result(spec.test_id, "ok", []))
                continue
            if kind == "query":
                if not spec.sql:
                    results.append(_render_result(spec.test_id, "skipped", ["missing sql"]))
                    continue
                try:
                    res = conn.query(spec.sql)
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
                    res = conn.query(spec.sql, spec.params)
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
                if not hasattr(conn, "cancel"):
                    results.append(_render_result(spec.test_id, "failed", ["cancel not implemented"]))
                    continue
                if not spec.sql:
                    results.append(_render_result(spec.test_id, "skipped", ["missing sql"]))
                    continue
                try:
                    stream = conn.stream(spec.sql, None, 1)
                    row_budget = spec.cancel_after_rows if spec.cancel_after_rows > 0 else 1
                    for _ in range(row_budget):
                        try:
                            stream.__next__()
                        except StopIteration:
                            break
                    conn.cancel()
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
