#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
PACKAGE_DIR="${ROOT_DIR}/tracks/alpha/integrations/scratchbird-sqlalchemy-dialect"
LOG_FILE="$SCRIPT_DIR/verification_sqlalchemy.log"
LATEST_LOG="$SCRIPT_DIR/latest_verification.log"

exec > >(tee "$LOG_FILE") 2>&1

PYTHON_BIN=""
if command -v python3 >/dev/null 2>&1; then
  PYTHON_BIN="python3"
elif command -v python >/dev/null 2>&1; then
  PYTHON_BIN="python"
fi

echo "ECOSYS-402 SQLAlchemy dialect verification"
echo "root: $ROOT_DIR"
echo "package: $PACKAGE_DIR"
echo

if [[ -z "$PYTHON_BIN" ]]; then
  echo "[fail] python runtime unavailable"
  cp "$LOG_FILE" "$LATEST_LOG"
  exit 1
fi

if [[ ! -d "$PACKAGE_DIR" ]]; then
  echo "[fail] SQLAlchemy dialect package not found"
  cp "$LOG_FILE" "$LATEST_LOG"
  exit 1
fi

echo "[step] deterministic dialect contract tests"
if (cd "$PACKAGE_DIR" && "$PYTHON_BIN" -m pytest -q tests/test_dialect_contract.py); then
  echo "[pass] deterministic dialect contract tests"
else
  echo "[fail] deterministic dialect contract tests"
  cp "$LOG_FILE" "$LATEST_LOG"
  exit 1
fi

echo
echo "[step] syntax verification"
if (cd "$PACKAGE_DIR" && "$PYTHON_BIN" -m py_compile scratchbird_sqlalchemy/dialect.py); then
  echo "[pass] dialect syntax check"
else
  echo "[fail] dialect syntax check"
  cp "$LOG_FILE" "$LATEST_LOG"
  exit 1
fi

echo
echo "[note] Live SQLAlchemy ORM/session integration is not executed here. Current shell runtime probe is blocked by TLS endpoint mismatch (see verification_sqlalchemy_runtime_probe.sh)."

cp "$LOG_FILE" "$LATEST_LOG"
