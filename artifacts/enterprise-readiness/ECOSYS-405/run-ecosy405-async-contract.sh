#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
LOG_FILE="$SCRIPT_DIR/verification_async_contract.log"
LATEST_LOG="$SCRIPT_DIR/latest_verification.log"

exec > >(tee "$LOG_FILE") 2>&1

deterministic_failures=0
runtime_failures=0

PYTHON_BIN=""
if command -v python3 >/dev/null 2>&1; then
  PYTHON_BIN="python3"
elif command -v python >/dev/null 2>&1; then
  PYTHON_BIN="python"
fi

echo "ECOSYS-405 async contract verification"
echo "root: $ROOT_DIR"
echo

if command -v go >/dev/null 2>&1; then
  echo "[step] go deterministic cancel/timeout contract tests"
  if (cd "$ROOT_DIR/tracks/alpha/drivers/go" && go test -count=1 -run 'TestDrainUntilReadyContextCancelSendsUrgentCancel|TestRowsContextCancelSendsUrgentCancel|TestSendSimpleQueryUsesContextDeadlineForTimeout' ./); then
    echo "[pass] go deterministic contract tests"
  else
    echo "[fail] go deterministic contract tests"
    deterministic_failures=$((deterministic_failures + 1))
  fi
else
  echo "[blocked] go runtime unavailable"
  deterministic_failures=$((deterministic_failures + 1))
fi

if [[ -n "$PYTHON_BIN" ]]; then
  echo "[step] python deterministic cancel/timeout contract tests"
  if (cd "$ROOT_DIR/tracks/alpha/drivers/python" && "$PYTHON_BIN" -m pytest -q \
      tests/test_txn_exec_parity.py::test_cancel_sends_urgent_cancel_message \
      tests/test_connection_auth_protocol.py::test_read_exact_maps_socket_timeout_to_operational_error \
      tests/test_connection_auth_protocol.py::test_read_exact_maps_oserror_to_operational_error \
      tests/test_connection_auth_protocol.py::test_connect_maps_timeout_to_operational_error \
      tests/test_connection_auth_protocol.py::test_connect_maps_oserror_to_operational_error); then
    echo "[pass] python deterministic contract tests"
  else
    echo "[fail] python deterministic contract tests"
    deterministic_failures=$((deterministic_failures + 1))
  fi
else
  echo "[blocked] python runtime unavailable"
  deterministic_failures=$((deterministic_failures + 1))
fi

echo
echo "[step] optional live cancel matrix"

if [[ -n "${SCRATCHBIRD_GO_URL:-}" && -n "${SCRATCHBIRD_GO_CANCEL_SQL:-}" ]]; then
  echo "[info] running go live cancel integration"
  if (cd "$ROOT_DIR/tracks/alpha/drivers/go" && go test -count=1 -run TestIntegrationCancel ./); then
    echo "[pass] go live cancel integration"
  else
    echo "[fail] go live cancel integration"
    runtime_failures=$((runtime_failures + 1))
  fi
else
  echo "[skip] go live cancel integration (requires SCRATCHBIRD_GO_URL + SCRATCHBIRD_GO_CANCEL_SQL)"
fi

if [[ -n "$PYTHON_BIN" && -n "${SCRATCHBIRD_TEST_DSN:-}" && -n "${SCRATCHBIRD_TEST_CANCEL_SQL:-}" ]]; then
  echo "[info] running python live cancel integration"
  if (cd "$ROOT_DIR/tracks/alpha/drivers/python" && "$PYTHON_BIN" -m pytest -q tests/test_integration.py::test_cancel_integration); then
    echo "[pass] python live cancel integration"
  else
    echo "[fail] python live cancel integration"
    runtime_failures=$((runtime_failures + 1))
  fi
else
  echo "[skip] python live cancel integration (requires SCRATCHBIRD_TEST_DSN + SCRATCHBIRD_TEST_CANCEL_SQL)"
fi

echo
if [[ "$deterministic_failures" -eq 0 && "$runtime_failures" -eq 0 ]]; then
  echo "[pass] ECOSYS-405 async contract verification complete"
elif [[ "$deterministic_failures" -eq 0 ]]; then
  echo "[warn] deterministic contract passed; runtime matrix has failures"
else
  echo "[fail] deterministic async contract checks failed"
fi

cp "$LOG_FILE" "$LATEST_LOG"

if [[ "$deterministic_failures" -ne 0 || "$runtime_failures" -ne 0 ]]; then
  exit 1
fi
