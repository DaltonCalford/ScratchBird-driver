#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
PACKAGE_DIR="${ROOT_DIR}/tracks/alpha/integrations/scratchbird-prisma-adapter"
LOG_FILE="${SCRIPT_DIR}/verification_prisma_runtime_probe.log"
LATEST_LOG="${SCRIPT_DIR}/latest_runtime_probe.log"

exec > >(tee "${LOG_FILE}") 2>&1

echo "ECOSYS-401 Prisma runtime probe"
echo "root: ${ROOT_DIR}"
echo "package: ${PACKAGE_DIR}"
echo

if ! command -v node >/dev/null 2>&1; then
  echo "[fail] node runtime not available"
  cp "${LOG_FILE}" "${LATEST_LOG}"
  exit 1
fi

if ! command -v npx >/dev/null 2>&1; then
  echo "[fail] npx runtime not available"
  cp "${LOG_FILE}" "${LATEST_LOG}"
  exit 1
fi

if [[ ! -d "${PACKAGE_DIR}" ]]; then
  echo "[fail] Prisma adapter package not found"
  cp "${LOG_FILE}" "${LATEST_LOG}"
  exit 1
fi

echo "[step] prisma validate against adapter schema"
set +e
(
  cd "${PACKAGE_DIR}"
  npx --yes prisma@6.9.0 validate --schema examples/schema.prisma
)
STATUS=$?
set -e

if [[ ${STATUS} -eq 0 ]]; then
  echo "[pass] Prisma runtime provider probe succeeded"
else
  echo "[blocked] Prisma runtime provider probe failed (likely provider integration missing)"
fi

cp "${LOG_FILE}" "${LATEST_LOG}"
exit ${STATUS}
