# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

import sys
import os
import scratchbird


class TestSpec:
    def __init__(self):
        self.test_id = ""
        self.kind = ""
        self.sql = ""
        self.expect_rows = -1
        self.requires = []
        self.params = []


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


def _run_query_tests(tests, dsn: str):
    results = []
    enable_prepare = os.environ.get("SCRATCHBIRD_MOJO_ENABLE_PREPARE_BIND", "").lower() in ("1", "true", "yes")
    enable_cancel = os.environ.get("SCRATCHBIRD_MOJO_ENABLE_CANCEL", "").lower() in ("1", "true", "yes")
    if not dsn:
        for spec in tests:
            results.append(_render_result(spec.test_id, "skipped", ["SCRATCHBIRD_MOJO_URL not set"]))
        return results

    cfg = scratchbird.ScratchBirdConfig(dsn)
    conn = scratchbird.connect(cfg)
    try:
        for spec in tests:
            if spec.kind == "query":
                if not spec.sql:
                    results.append(_render_result(spec.test_id, "skipped", ["missing sql"]))
                    continue
                try:
                    res = conn.query(spec.sql)
                    if spec.expect_rows >= 0 and len(res.rows) != spec.expect_rows:
                        results.append(_render_result(spec.test_id, "failed", ["row count mismatch"]))
                    else:
                        results.append(_render_result(spec.test_id, "ok", []))
                except Exception as exc:
                    results.append(_render_result(spec.test_id, "failed", [str(exc)]))
                continue
            if spec.kind == "prepare_bind":
                if not enable_prepare:
                    results.append(_render_result(spec.test_id, "skipped", ["prepare_bind disabled"]))
                    continue
                if not spec.sql:
                    results.append(_render_result(spec.test_id, "skipped", ["missing sql"]))
                    continue
                try:
                    res = conn.query(spec.sql, spec.params)
                    if spec.expect_rows >= 0 and len(res.rows) != spec.expect_rows:
                        results.append(_render_result(spec.test_id, "failed", ["row count mismatch"]))
                    else:
                        results.append(_render_result(spec.test_id, "ok", []))
                except Exception as exc:
                    results.append(_render_result(spec.test_id, "failed", [str(exc)]))
                continue
            if spec.kind == "cancel":
                if not enable_cancel:
                    results.append(_render_result(spec.test_id, "skipped", ["cancel disabled"]))
                    continue
                if not hasattr(conn, "cancel"):
                    results.append(_render_result(spec.test_id, "failed", ["cancel not implemented"]))
                    continue
                results.append(_render_result(spec.test_id, "skipped", ["cancel requires streaming support"]))
                continue
            results.append(_render_result(spec.test_id, "skipped", ["unsupported kind"]))
    finally:
        conn.close()
    return results


def main():
    manifest = ""
    args = sys.argv
    if "--manifest" in args:
        idx = args.index("--manifest")
        if idx + 1 < len(args):
            manifest = args[idx + 1]
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
