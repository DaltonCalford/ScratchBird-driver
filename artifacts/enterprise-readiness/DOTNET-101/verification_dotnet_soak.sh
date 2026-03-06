#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
PROJECT_PATH="${ROOT_DIR}/tracks/alpha/drivers/dotnet/tests/ScratchBird.Data.Tests/ScratchBird.Data.Tests.csproj"
LOG_BASENAME="verification_dotnet_soak_harness"
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

echo "DOTNET-101 soak harness verification"
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
  export SCRATCHBIRD_DOTNET_SOAK_ENABLE=1
  export SCRATCHBIRD_DOTNET_SOAK_SECONDS="${SCRATCHBIRD_DOTNET_SOAK_SECONDS:-900}"
  export SCRATCHBIRD_DOTNET_SOAK_MIN_ITERATIONS="${SCRATCHBIRD_DOTNET_SOAK_MIN_ITERATIONS:-25}"
  export SCRATCHBIRD_DOTNET_SOAK_MIN_VERIFY_READS="${SCRATCHBIRD_DOTNET_SOAK_MIN_VERIFY_READS:-5}"

  min_seconds="${SCRATCHBIRD_DOTNET_SOAK_MIN_SECONDS:-600}"
  if [[ "${ALLOW_SHORT_RUNTIME}" != "1" && "${SCRATCHBIRD_DOTNET_SOAK_SECONDS}" -lt "${min_seconds}" ]]; then
    echo "[fail] SCRATCHBIRD_DOTNET_SOAK_SECONDS (${SCRATCHBIRD_DOTNET_SOAK_SECONDS}) is below SCRATCHBIRD_DOTNET_SOAK_MIN_SECONDS (${min_seconds})"
    echo "       Set DOTNET_HARNESS_ALLOW_SHORT_RUNTIME=1 to bypass this guard for short local checks."
    exit 1
  fi

  if [[ -z "${SCRATCHBIRD_DOTNET_URL:-}" ]]; then
    echo "[fail] runtime mode requires SCRATCHBIRD_DOTNET_URL"
    exit 1
  fi

  echo "[step] runtime soak enabled"
  echo "[step] seconds=${SCRATCHBIRD_DOTNET_SOAK_SECONDS}, minIterations=${SCRATCHBIRD_DOTNET_SOAK_MIN_ITERATIONS}, minVerifyReads=${SCRATCHBIRD_DOTNET_SOAK_MIN_VERIFY_READS}"
else
  unset SCRATCHBIRD_DOTNET_SOAK_ENABLE || true
  unset SCRATCHBIRD_DOTNET_SOAK_MIN_ITERATIONS || true
  unset SCRATCHBIRD_DOTNET_SOAK_MIN_VERIFY_READS || true
  echo "[step] deterministic contract mode (runtime soak disabled)"
fi

if dotnet test "${PROJECT_PATH}" \
  --filter FullyQualifiedName~SoakAndFaultInjectionTests.CancellationReleaseSoakHarness \
  --verbosity normal; then
  if [[ "${MODE}" == "runtime" ]]; then
    summary_line="$(grep -F "DOTNET-101 soak summary:" "${LOG_FILE}" | tail -n 1 || true)"
    if [[ -z "${summary_line}" ]]; then
      echo "[fail] runtime soak completed but summary line was not found in log"
      exit 1
    fi
    echo "[info] ${summary_line}"
  fi
  echo "[pass] DOTNET-101 soak harness verification"
else
  echo "[fail] DOTNET-101 soak harness verification"
  exit 1
fi

echo
if [[ "${MODE}" != "runtime" ]]; then
  echo "[note] Set DOTNET_HARNESS_MODE=runtime and SCRATCHBIRD_DOTNET_URL to execute sustained soak."
fi
