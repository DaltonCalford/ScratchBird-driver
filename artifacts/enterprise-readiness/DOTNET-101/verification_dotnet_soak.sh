#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
PROJECT_PATH="${ROOT_DIR}/tracks/alpha/drivers/dotnet/tests/ScratchBird.Data.Tests/ScratchBird.Data.Tests.csproj"
LOG_BASENAME="verification_dotnet_soak_harness"
MODE="${DOTNET_HARNESS_MODE:-deterministic}"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG_FILE="${SCRIPT_DIR}/${LOG_BASENAME}_${TS}.log"
LATEST_LOG="${SCRIPT_DIR}/latest_verification.log"

exec > >(tee "${LOG_FILE}") 2>&1

echo "DOTNET-101 soak harness verification"
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
  export SCRATCHBIRD_DOTNET_SOAK_ENABLE=1
  export SCRATCHBIRD_DOTNET_SOAK_SECONDS="${SCRATCHBIRD_DOTNET_SOAK_SECONDS:-300}"

  if [[ -z "${SCRATCHBIRD_DOTNET_URL:-}" ]]; then
    echo "[fail] runtime mode requires SCRATCHBIRD_DOTNET_URL"
    cp "${LOG_FILE}" "${LATEST_LOG}"
    exit 1
  fi

  echo "[step] runtime soak test enabled"
else
  unset SCRATCHBIRD_DOTNET_SOAK_ENABLE || true
  echo "[step] deterministic contract mode (runtime soak disabled)"
fi

if dotnet test "${PROJECT_PATH}" --filter FullyQualifiedName~SoakAndFaultInjectionTests.CancellationReleaseSoakHarness --verbosity minimal; then
  echo "[pass] DOTNET-101 soak harness verification"
else
  echo "[fail] DOTNET-101 soak harness verification"
  cp "${LOG_FILE}" "${LATEST_LOG}"
  exit 1
fi

echo
if [[ "${MODE}" != "runtime" ]]; then
  echo "[note] Set DOTNET_HARNESS_MODE=runtime and SCRATCHBIRD_DOTNET_URL to execute long-running soak."
fi

cp "${LOG_FILE}" "${LATEST_LOG}"
