#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
PROJECT_PATH="${ROOT_DIR}/tracks/alpha/drivers/dotnet/tests/ScratchBird.Data.Tests/ScratchBird.Data.Tests.csproj"
LOG_BASENAME="verification_dotnet_fault_matrix_harness"
MODE="${DOTNET_HARNESS_MODE:-deterministic}"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG_FILE="${SCRIPT_DIR}/${LOG_BASENAME}_${TS}.log"
LATEST_LOG="${SCRIPT_DIR}/latest_verification.log"

exec > >(tee "${LOG_FILE}") 2>&1

echo "DOTNET-103 isolation/fault matrix harness verification"
echo "root: ${ROOT_DIR}"
echo "mode: ${MODE}"
echo

if ! command -v dotnet >/dev/null 2>&1; then
  echo "[fail] dotnet runtime not available"
  cp "${LOG_FILE}" "${LATEST_LOG}"
  exit 1
fi

if [[ ! -f "${PROJECT_PATH}" ]]; then
  echo "[fail] test project not found: ${PROJECT_PATH}"
  cp "${LOG_FILE}" "${LATEST_LOG}"
  exit 1
fi

if [[ "${MODE}" == "runtime" ]]; then
  export SCRATCHBIRD_DOTNET_FAULT_MATRIX_ENABLE=1

  if [[ -z "${SCRATCHBIRD_DOTNET_URL:-}" ]]; then
    echo "[fail] runtime mode requires SCRATCHBIRD_DOTNET_URL"
    cp "${LOG_FILE}" "${LATEST_LOG}"
    exit 1
  fi

  echo "[step] runtime fault matrix enabled"
else
  unset SCRATCHBIRD_DOTNET_FAULT_MATRIX_ENABLE || true
  echo "[step] deterministic contract mode (runtime fault matrix disabled)"
fi

if dotnet test "${PROJECT_PATH}" --filter FullyQualifiedName~SoakAndFaultInjectionTests.IsolationAndDeadlockFaultInjectionMatrixHarness --verbosity minimal; then
  echo "[pass] DOTNET-103 fault matrix harness verification"
else
  echo "[fail] DOTNET-103 fault matrix harness verification"
  cp "${LOG_FILE}" "${LATEST_LOG}"
  exit 1
fi

echo
if [[ "${MODE}" != "runtime" ]]; then
  echo "[note] Set DOTNET_HARNESS_MODE=runtime and SCRATCHBIRD_DOTNET_URL to execute runtime fault-injection matrix."
fi

cp "${LOG_FILE}" "${LATEST_LOG}"
