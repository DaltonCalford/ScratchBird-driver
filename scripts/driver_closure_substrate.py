#!/usr/bin/env python3
"""Shared cross-driver closure substrate for conformance and SQLSTATE gates."""

from __future__ import annotations

import argparse
import csv
import json
import sys
from collections import Counter
from pathlib import Path
from typing import Any


def _load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def _repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def _resolve_contract_path(contract_path: Path, raw: str) -> Path:
    candidate = Path(raw)
    if candidate.is_absolute():
        return candidate
    relative_to_contract = (contract_path.parent / candidate).resolve()
    if relative_to_contract.exists():
        return relative_to_contract
    return (_repo_root() / candidate).resolve()


def _normalize_conformance_results(payload: Any) -> list[dict[str, Any]]:
    if isinstance(payload, list):
        results = payload
    elif isinstance(payload, dict):
        if isinstance(payload.get("results"), list):
            results = payload["results"]
        elif isinstance(payload.get("conformance_results"), list):
            results = payload["conformance_results"]
        else:
            raise ValueError("conformance payload missing results array")
    else:
        raise ValueError("conformance payload must be an array or object")

    normalized: list[dict[str, Any]] = []
    for item in results:
        if not isinstance(item, dict):
            raise ValueError("conformance result entries must be objects")
        test_id = item.get("test_id") or item.get("id")
        if not isinstance(test_id, str) or not test_id:
            raise ValueError("conformance result missing test_id")
        status = item.get("status", "unknown")
        if not isinstance(status, str) or not status:
            raise ValueError(f"conformance result {test_id!r} missing status")
        normalized.append({"test_id": test_id, "status": status})
    return normalized


def _normalize_sqlstate_codes(payload: Any) -> list[str]:
    if isinstance(payload, list):
        codes = payload
    elif isinstance(payload, dict):
        if isinstance(payload.get("supported_codes"), list):
            codes = payload["supported_codes"]
        elif isinstance(payload.get("sqlstates"), list):
            codes = payload["sqlstates"]
        else:
            raise ValueError("sqlstate payload missing supported_codes array")
    else:
        raise ValueError("sqlstate payload must be an array or object")

    normalized = []
    for code in codes:
        if not isinstance(code, str) or not code:
            raise ValueError("sqlstate codes must be non-empty strings")
        normalized.append(code.upper())
    return sorted(set(normalized))


def _validate_contract(contract: dict[str, Any], sqlstate_contract: dict[str, Any]) -> None:
    required_tests = contract.get("required_conformance_tests")
    if not isinstance(required_tests, list) or not required_tests:
        raise ValueError("contract must define required_conformance_tests")
    seen_test_ids = set()
    for entry in required_tests:
        if not isinstance(entry, dict):
            raise ValueError("required_conformance_tests entries must be objects")
        test_id = entry.get("id")
        allowed_statuses = entry.get("allowed_statuses")
        if not isinstance(test_id, str) or not test_id:
            raise ValueError("required conformance test missing id")
        if test_id in seen_test_ids:
            raise ValueError(f"duplicate required conformance test {test_id}")
        seen_test_ids.add(test_id)
        if not isinstance(allowed_statuses, list) or not allowed_statuses:
            raise ValueError(f"required conformance test {test_id} missing allowed_statuses")

    required_sqlstates = sqlstate_contract.get("required_sqlstates")
    if not isinstance(required_sqlstates, list) or not required_sqlstates:
        raise ValueError("sqlstate contract must define required_sqlstates")
    seen_codes = set()
    for entry in required_sqlstates:
        if not isinstance(entry, dict):
            raise ValueError("required_sqlstates entries must be objects")
        code = entry.get("code")
        sqlstate_class = entry.get("class")
        retriable = entry.get("retriable")
        if not isinstance(code, str) or len(code) != 5:
            raise ValueError("sqlstate contract entry missing 5-char code")
        if code in seen_codes:
            raise ValueError(f"duplicate sqlstate code {code}")
        seen_codes.add(code)
        if not isinstance(sqlstate_class, str) or len(sqlstate_class) != 2:
            raise ValueError(f"sqlstate contract entry {code} missing class")
        if not isinstance(retriable, bool):
            raise ValueError(f"sqlstate contract entry {code} missing boolean retriable")


def _load_contracts(contract_path: Path) -> tuple[dict[str, Any], dict[str, Any], Path]:
    contract = _load_json(contract_path)
    if not isinstance(contract, dict):
        raise ValueError("driver closure contract must be an object")
    sqlstate_contract_path = _resolve_contract_path(contract_path, contract["sqlstate_contract"])
    sqlstate_contract = _load_json(sqlstate_contract_path)
    if not isinstance(sqlstate_contract, dict):
        raise ValueError("sqlstate contract must be an object")
    _validate_contract(contract, sqlstate_contract)
    return contract, sqlstate_contract, sqlstate_contract_path


def summarize_driver(
    contract: dict[str, Any],
    sqlstate_contract: dict[str, Any],
    driver_id: str,
    lane: str,
    conformance_payload: Any,
    sqlstate_payload: Any,
) -> dict[str, Any]:
    normalized_results = _normalize_conformance_results(conformance_payload)
    normalized_codes = _normalize_sqlstate_codes(sqlstate_payload)
    result_map = {entry["test_id"]: entry for entry in normalized_results}

    missing_tests: list[str] = []
    failing_tests: list[dict[str, str]] = []
    for required in contract["required_conformance_tests"]:
        test_id = required["id"]
        actual = result_map.get(test_id)
        if actual is None:
            missing_tests.append(test_id)
            continue
        if actual["status"] not in required["allowed_statuses"]:
            failing_tests.append(
                {
                    "test_id": test_id,
                    "status": actual["status"],
                    "allowed_statuses": ",".join(required["allowed_statuses"]),
                }
            )

    required_codes = [entry["code"] for entry in sqlstate_contract["required_sqlstates"]]
    missing_sqlstates = [code for code in required_codes if code not in normalized_codes]
    extra_sqlstates = [code for code in normalized_codes if code not in required_codes]
    status_counts = Counter(entry["status"] for entry in normalized_results)

    conformance_status = "pass" if not missing_tests and not failing_tests else "fail"
    sqlstate_status = "pass" if not missing_sqlstates else "fail"
    overall_status = "pass" if conformance_status == "pass" and sqlstate_status == "pass" else "fail"

    return {
        "schema_version": "1.0",
        "driver_id": driver_id,
        "lane": lane,
        "status": overall_status,
        "conformance_status": conformance_status,
        "sqlstate_status": sqlstate_status,
        "required_test_count": len(contract["required_conformance_tests"]),
        "observed_test_count": len(normalized_results),
        "required_sqlstate_count": len(required_codes),
        "observed_sqlstate_count": len(normalized_codes),
        "missing_tests": missing_tests,
        "failing_tests": failing_tests,
        "missing_sqlstates": missing_sqlstates,
        "extra_sqlstates": extra_sqlstates,
        "status_counts": dict(status_counts),
        "supported_sqlstates": normalized_codes,
    }


def _write_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, sort_keys=True)
        handle.write("\n")


def _write_csv(path: Path, rows: list[dict[str, Any]], columns: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=columns)
        writer.writeheader()
        for row in rows:
            writer.writerow(row)


def command_validate_contracts(args: argparse.Namespace) -> int:
    contract, sqlstate_contract, sqlstate_contract_path = _load_contracts(args.contract)
    payload = {
        "status": "ok",
        "suite_id": contract.get("suite_id"),
        "required_conformance_tests": len(contract["required_conformance_tests"]),
        "required_sqlstates": len(sqlstate_contract["required_sqlstates"]),
        "sqlstate_contract_path": str(sqlstate_contract_path),
    }
    json.dump(payload, sys.stdout, indent=2, sort_keys=True)
    sys.stdout.write("\n")
    return 0


def command_summarize(args: argparse.Namespace) -> int:
    contract, sqlstate_contract, _ = _load_contracts(args.contract)
    summary = summarize_driver(
        contract=contract,
        sqlstate_contract=sqlstate_contract,
        driver_id=args.driver_id,
        lane=args.lane,
        conformance_payload=_load_json(args.conformance_results),
        sqlstate_payload=_load_json(args.sqlstate_codes),
    )
    if args.output:
        _write_json(args.output, summary)
    json.dump(summary, sys.stdout, indent=2, sort_keys=True)
    sys.stdout.write("\n")
    return 0 if summary["status"] == "pass" else 1


def command_matrix(args: argparse.Namespace) -> int:
    contract, _, _ = _load_contracts(args.contract)
    summaries = [_load_json(path) for path in args.driver_summary]
    rows: list[dict[str, Any]] = []
    for summary in summaries:
        if not isinstance(summary, dict):
            raise ValueError("driver summary payloads must be objects")
        rows.append(
            {
                "driver_id": summary.get("driver_id", ""),
                "lane": summary.get("lane", ""),
                "status": summary.get("status", ""),
                "conformance_status": summary.get("conformance_status", ""),
                "sqlstate_status": summary.get("sqlstate_status", ""),
                "missing_tests": ";".join(summary.get("missing_tests", [])),
                "failing_tests": ";".join(
                    f"{item.get('test_id')}:{item.get('status')}"
                    for item in summary.get("failing_tests", [])
                    if isinstance(item, dict)
                ),
                "missing_sqlstates": ";".join(summary.get("missing_sqlstates", [])),
            }
        )

    rows.sort(key=lambda row: (row["lane"], row["driver_id"]))
    matrix = {
        "schema_version": "1.0",
        "suite_id": contract.get("suite_id"),
        "driver_count": len(rows),
        "rows": rows,
    }
    if args.output_json:
        _write_json(args.output_json, matrix)
    if args.output_csv:
        _write_csv(args.output_csv, rows, contract["matrix_columns"])
    json.dump(matrix, sys.stdout, indent=2, sort_keys=True)
    sys.stdout.write("\n")
    return 0 if all(row["status"] == "pass" for row in rows) else 1


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    validate = subparsers.add_parser("validate-contracts", help="validate shared closure contracts")
    validate.add_argument("--contract", type=Path, default=_repo_root() / "docs/fixtures/driver_closure_substrate.json")
    validate.set_defaults(func=command_validate_contracts)

    summarize = subparsers.add_parser("summarize", help="normalize one driver lane into a closure summary")
    summarize.add_argument("--contract", type=Path, default=_repo_root() / "docs/fixtures/driver_closure_substrate.json")
    summarize.add_argument("--driver-id", required=True)
    summarize.add_argument("--lane", required=True)
    summarize.add_argument("--conformance-results", type=Path, required=True)
    summarize.add_argument("--sqlstate-codes", type=Path, required=True)
    summarize.add_argument("--output", type=Path)
    summarize.set_defaults(func=command_summarize)

    matrix = subparsers.add_parser("matrix", help="merge driver summaries into a promotion matrix")
    matrix.add_argument("--contract", type=Path, default=_repo_root() / "docs/fixtures/driver_closure_substrate.json")
    matrix.add_argument("--driver-summary", type=Path, action="append", required=True)
    matrix.add_argument("--output-json", type=Path)
    matrix.add_argument("--output-csv", type=Path)
    matrix.set_defaults(func=command_matrix)
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        return args.func(args)
    except ValueError as exc:
        parser.error(str(exc))
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
