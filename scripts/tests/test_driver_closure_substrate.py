import json
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts" / "driver_closure_substrate.py"
CONTRACT = ROOT / "docs" / "fixtures" / "driver_closure_substrate.json"


def _write_json(path: Path, payload):
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def _run(*args):
    return subprocess.run(
        [sys.executable, str(SCRIPT), *args],
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=False,
    )


def test_validate_contracts_passes():
    result = _run("validate-contracts", "--contract", str(CONTRACT))
    assert result.returncode == 0, result.stderr
    payload = json.loads(result.stdout)
    assert payload["status"] == "ok"
    assert payload["required_conformance_tests"] >= 6
    assert payload["required_sqlstates"] >= 40


def test_summarize_accepts_raw_conformance_array(tmp_path):
    conformance = [
        {"test_id": "handshake", "status": "ok"},
        {"test_id": "auth", "status": "ok"},
        {"test_id": "prepare_bind", "status": "ok"},
        {"test_id": "describe_param_mismatch", "status": "ok"},
        {"test_id": "types_one_way", "status": "ok"},
        {"test_id": "paging_basic_table", "status": "ok"},
        {"test_id": "cancel_stream", "status": "skipped"},
    ]
    sqlstate_codes = json.loads((ROOT / "docs" / "fixtures" / "sqlstate_required_set.json").read_text(encoding="utf-8"))
    conformance_path = tmp_path / "go_conformance.json"
    sqlstate_path = tmp_path / "go_sqlstates.json"
    summary_path = tmp_path / "go_summary.json"
    _write_json(conformance_path, conformance)
    _write_json(sqlstate_path, {"supported_codes": [entry["code"] for entry in sqlstate_codes["required_sqlstates"]]})

    result = _run(
        "summarize",
        "--contract",
        str(CONTRACT),
        "--driver-id",
        "go",
        "--lane",
        "alpha-primary",
        "--conformance-results",
        str(conformance_path),
        "--sqlstate-codes",
        str(sqlstate_path),
        "--output",
        str(summary_path),
    )

    assert result.returncode == 0, result.stderr
    payload = json.loads(result.stdout)
    assert payload["status"] == "pass"
    assert payload["missing_tests"] == []
    assert payload["missing_sqlstates"] == []
    assert summary_path.exists()


def test_summarize_flags_missing_test_and_sqlstate(tmp_path):
    conformance_path = tmp_path / "node_conformance.json"
    sqlstate_path = tmp_path / "node_sqlstates.json"
    _write_json(
        conformance_path,
        {"results": [{"test_id": "handshake", "status": "ok"}, {"test_id": "auth", "status": "error"}]},
    )
    _write_json(sqlstate_path, ["08001", "08003", "23505"])

    result = _run(
        "summarize",
        "--contract",
        str(CONTRACT),
        "--driver-id",
        "node",
        "--lane",
        "alpha-primary",
        "--conformance-results",
        str(conformance_path),
        "--sqlstate-codes",
        str(sqlstate_path),
    )

    assert result.returncode == 1
    payload = json.loads(result.stdout)
    assert payload["status"] == "fail"
    assert "prepare_bind" in payload["missing_tests"]
    assert "01000" in payload["missing_sqlstates"]


def test_matrix_merges_driver_summaries(tmp_path):
    good_summary = {
        "driver_id": "go",
        "lane": "alpha-primary",
        "status": "pass",
        "conformance_status": "pass",
        "sqlstate_status": "pass",
        "missing_tests": [],
        "failing_tests": [],
        "missing_sqlstates": [],
    }
    bad_summary = {
        "driver_id": "dart",
        "lane": "beta",
        "status": "fail",
        "conformance_status": "fail",
        "sqlstate_status": "fail",
        "missing_tests": ["types_one_way"],
        "failing_tests": [{"test_id": "auth", "status": "error"}],
        "missing_sqlstates": ["23505"],
    }
    good_path = tmp_path / "go_summary.json"
    bad_path = tmp_path / "dart_summary.json"
    matrix_json = tmp_path / "matrix.json"
    matrix_csv = tmp_path / "matrix.csv"
    _write_json(good_path, good_summary)
    _write_json(bad_path, bad_summary)

    result = _run(
        "matrix",
        "--contract",
        str(CONTRACT),
        "--driver-summary",
        str(good_path),
        "--driver-summary",
        str(bad_path),
        "--output-json",
        str(matrix_json),
        "--output-csv",
        str(matrix_csv),
    )

    assert result.returncode == 1
    payload = json.loads(result.stdout)
    assert payload["driver_count"] == 2
    assert matrix_json.exists()
    csv_lines = matrix_csv.read_text(encoding="utf-8").strip().splitlines()
    assert csv_lines[0].startswith("driver_id,lane,status")
    assert any("dart,beta,fail" in line for line in csv_lines[1:])
