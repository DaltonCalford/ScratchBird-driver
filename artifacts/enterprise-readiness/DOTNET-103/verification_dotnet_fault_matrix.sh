#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
PROJECT_PATH="${ROOT_DIR}/tracks/alpha/drivers/dotnet/tests/ScratchBird.Data.Tests/ScratchBird.Data.Tests.csproj"
LOG_BASENAME="verification_dotnet_fault_matrix_harness"
MODE="${DOTNET_HARNESS_MODE:-deterministic}"
ALLOW_SHORT_RUNTIME="${DOTNET_HARNESS_ALLOW_SHORT_RUNTIME:-0}"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG_FILE="${SCRIPT_DIR}/${LOG_BASENAME}_${TS}.log"
LATEST_LOG="${SCRIPT_DIR}/latest_verification.log"

finalize() {
  cp "${LOG_FILE}" "${LATEST_LOG}"
}
trap finalize EXIT

exec > >(tee "${LOG_FILE}") 2>&1

echo "DOTNET-103 isolation/fault matrix harness verification"
echo "root: ${ROOT_DIR}"
echo "mode: ${MODE}"
echo

if ! command -v dotnet >/dev/null 2>&1; then
  echo "[fail] dotnet runtime not available"
  exit 1
fi

if [[ ! -f "${PROJECT_PATH}" ]]; then
  echo "[fail] test project not found: ${PROJECT_PATH}"
  exit 1
fi

if [[ "${MODE}" == "runtime" ]]; then
  export SCRATCHBIRD_DOTNET_FAULT_MATRIX_ENABLE=1
  export SCRATCHBIRD_DOTNET_FAULT_MATRIX_ROUNDS="${SCRATCHBIRD_DOTNET_FAULT_MATRIX_ROUNDS:-24}"

  min_rounds="${SCRATCHBIRD_DOTNET_FAULT_MATRIX_MIN_ROUNDS:-12}"
  if [[ "${ALLOW_SHORT_RUNTIME}" != "1" && "${SCRATCHBIRD_DOTNET_FAULT_MATRIX_ROUNDS}" -lt "${min_rounds}" ]]; then
    echo "[fail] SCRATCHBIRD_DOTNET_FAULT_MATRIX_ROUNDS (${SCRATCHBIRD_DOTNET_FAULT_MATRIX_ROUNDS}) is below SCRATCHBIRD_DOTNET_FAULT_MATRIX_MIN_ROUNDS (${min_rounds})"
    echo "       Set DOTNET_HARNESS_ALLOW_SHORT_RUNTIME=1 to bypass this guard for short local checks."
    exit 1
  fi

  if [[ -z "${SCRATCHBIRD_DOTNET_URL:-}" ]]; then
    echo "[fail] runtime mode requires SCRATCHBIRD_DOTNET_URL"
    exit 1
  fi

  echo "[step] runtime fault matrix enabled"
  echo "[step] rounds=${SCRATCHBIRD_DOTNET_FAULT_MATRIX_ROUNDS}"
else
  unset SCRATCHBIRD_DOTNET_FAULT_MATRIX_ENABLE || true
  unset SCRATCHBIRD_DOTNET_FAULT_MATRIX_ROUNDS || true
  echo "[step] deterministic contract mode (runtime fault matrix disabled)"
fi

if dotnet test "${PROJECT_PATH}" \
  --filter FullyQualifiedName~SoakAndFaultInjectionTests.IsolationAndDeadlockFaultInjectionMatrixHarness \
  --verbosity normal; then
  if [[ "${MODE}" == "runtime" ]]; then
    summary_line="$(grep -F "DOTNET-103 fault-matrix summary:" "${LOG_FILE}" | tail -n 1 || true)"
    if [[ -z "${summary_line}" ]]; then
      echo "[fail] runtime fault matrix completed but summary line was not found in log"
      exit 1
    fi
    echo "[info] ${summary_line}"
  fi
  echo "[pass] DOTNET-103 fault matrix harness verification"
else
  echo "[fail] DOTNET-103 fault matrix harness verification"
  exit 1
fi

echo
if [[ "${MODE}" != "runtime" ]]; then
  echo "[note] Set DOTNET_HARNESS_MODE=runtime and SCRATCHBIRD_DOTNET_URL to execute runtime fault-injection matrix."
fi
