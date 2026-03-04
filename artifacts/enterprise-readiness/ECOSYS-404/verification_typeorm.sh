#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
PACKAGE_DIR="${ROOT_DIR}/tracks/alpha/integrations/scratchbird-typeorm-adapter"
LOG_FILE="$SCRIPT_DIR/verification_typeorm.log"
LATEST_LOG="$SCRIPT_DIR/latest_verification.log"

exec > >(tee "$LOG_FILE") 2>&1

echo "ECOSYS-404 TypeORM adapter verification"
echo "root: $ROOT_DIR"
echo "package: $PACKAGE_DIR"
echo

if ! command -v node >/dev/null 2>&1; then
  echo "[fail] node runtime not available"
  cp "$LOG_FILE" "$LATEST_LOG"
  exit 1
fi

if [[ ! -d "$PACKAGE_DIR" ]]; then
  echo "[fail] TypeORM adapter package not found"
  cp "$LOG_FILE" "$LATEST_LOG"
  exit 1
fi

echo "[step] deterministic Node contract suite"
if (cd "$PACKAGE_DIR" && node --test); then
  echo "[pass] deterministic Node contract suite"
else
  echo "[fail] deterministic Node contract suite"
  cp "$LOG_FILE" "$LATEST_LOG"
  exit 1
fi

echo
echo "[step] module load smoke"
if (cd "$PACKAGE_DIR" && node -e 'const adapter=require("./lib/index"); if (!adapter.generateEntitySchemas || !adapter.normalizeTypeOrmOptions) process.exit(1);'); then
  echo "[pass] module load smoke"
else
  echo "[fail] module load smoke"
  cp "$LOG_FILE" "$LATEST_LOG"
  exit 1
fi

echo
echo "[note] Live TypeORM runtime schema/CRUD/transaction matrix is not executed here. Current blocker: TypeORM MissingDriverError for type=\\\"scratchbird\\\" (see verification_typeorm_runtime_probe.sh)."

cp "$LOG_FILE" "$LATEST_LOG"
