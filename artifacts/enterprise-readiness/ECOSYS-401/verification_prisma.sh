#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
PACKAGE_DIR="${ROOT_DIR}/tracks/alpha/integrations/scratchbird-prisma-adapter"
LOG_FILE="$SCRIPT_DIR/verification_prisma.log"
LATEST_LOG="$SCRIPT_DIR/latest_verification.log"

exec > >(tee "$LOG_FILE") 2>&1

echo "ECOSYS-401 Prisma adapter verification"
echo "root: $ROOT_DIR"
echo "package: $PACKAGE_DIR"
echo

if ! command -v node >/dev/null 2>&1; then
  echo "[fail] node runtime not available"
  cp "$LOG_FILE" "$LATEST_LOG"
  exit 1
fi

if [[ ! -d "$PACKAGE_DIR" ]]; then
  echo "[fail] Prisma adapter package not found"
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
if (cd "$PACKAGE_DIR" && node -e 'const adapter=require("./lib/index"); if (!adapter.generatePrismaSchemaFromMetadata || !adapter.runReflectionRoundTripContract || !adapter.buildDeterministicMigrationPlan) process.exit(1);'); then
  echo "[pass] module load smoke"
else
  echo "[fail] module load smoke"
  cp "$LOG_FILE" "$LATEST_LOG"
  exit 1
fi

echo
echo "[note] Live Prisma CLI migration/introspection/CRUD matrix is not executed here. Current blocker: Prisma CLI rejects provider=\\\"scratchbird\\\" (see verification_prisma_runtime_probe.sh)."

cp "$LOG_FILE" "$LATEST_LOG"
