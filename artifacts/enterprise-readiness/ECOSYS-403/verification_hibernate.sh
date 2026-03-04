#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
PACKAGE_DIR="${ROOT_DIR}/tracks/alpha/integrations/scratchbird-hibernate-dialect"
LOG_FILE="$SCRIPT_DIR/verification_hibernate.log"
LATEST_LOG="$SCRIPT_DIR/latest_verification.log"

exec > >(tee "$LOG_FILE") 2>&1

echo "ECOSYS-403 Hibernate dialect verification"
echo "root: $ROOT_DIR"
echo "package: $PACKAGE_DIR"
echo

if ! command -v java >/dev/null 2>&1; then
  echo "[fail] java runtime not available"
  cp "$LOG_FILE" "$LATEST_LOG"
  exit 1
fi

if ! command -v mvn >/dev/null 2>&1; then
  echo "[fail] maven runtime not available"
  cp "$LOG_FILE" "$LATEST_LOG"
  exit 1
fi

if [[ ! -d "$PACKAGE_DIR" ]]; then
  echo "[fail] Hibernate dialect package not found"
  cp "$LOG_FILE" "$LATEST_LOG"
  exit 1
fi

echo "[step] deterministic Hibernate contract tests"
if (cd "$PACKAGE_DIR" && mvn -q test); then
  echo "[pass] deterministic Hibernate contract tests"
else
  echo "[fail] deterministic Hibernate contract tests"
  cp "$LOG_FILE" "$LATEST_LOG"
  exit 1
fi

echo
echo "[step] syntax compilation check"
if (cd "$PACKAGE_DIR" && mvn -q -DskipTests compile); then
  echo "[pass] syntax compilation check"
else
  echo "[fail] syntax compilation check"
  cp "$LOG_FILE" "$LATEST_LOG"
  exit 1
fi

echo
echo "[note] Live JPA bootstrap/entity lifecycle/migration runtime matrix is not executed here. Current blocker: JDBC runtime classpath/bootstrap (see verification_hibernate_runtime_probe.sh)."

cp "$LOG_FILE" "$LATEST_LOG"
