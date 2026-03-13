#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
STACK_SCRIPT="${SCRIPT_DIR}/driver_runtime_stack.sh"

SCRATCHBIRD_REPO="${SCRATCHBIRD_REPO:-${REPO_ROOT}/../ScratchBird}"
MODE="${SB_DRIVER_STACK_MODE:-static}"
IMPORT_BUNDLE="${SB_DRIVER_IMPORT_BUNDLE:-0}"

RUN_JDBC=1
RUN_ODBC=1
START_STACK=1
LOAD_FIXTURES=1

usage() {
  cat <<'USAGE'
Usage: scripts/run_jdbc_odbc_runtime_checks.sh [options]

Runs JDBC and ODBC driver checks against a live ScratchBird stack
(server + parser + listener), with shared fixtures loaded first.

Options:
  --scratchbird-repo <path>   ScratchBird repo root (default: ../ScratchBird)
  --mode <static|dynamic>     Stack mode (default: static)
  --import-bundle <0|1>       Import example bundle when starting stack (default: 0)
  --jdbc-only                 Run JDBC checks only
  --odbc-only                 Run ODBC checks only
  --no-start                  Assume stack already running
  --no-fixtures               Skip fixture reload
  --help                      Show help
USAGE
}

log() {
  printf '[driver-runtime-checks] %s\n' "$*"
}

die() {
  printf '[driver-runtime-checks] error: %s\n' "$*" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scratchbird-repo)
      SCRATCHBIRD_REPO="$2"
      shift 2
      ;;
    --mode)
      MODE="$2"
      shift 2
      ;;
    --import-bundle)
      IMPORT_BUNDLE="$2"
      shift 2
      ;;
    --jdbc-only)
      RUN_JDBC=1
      RUN_ODBC=0
      shift
      ;;
    --odbc-only)
      RUN_JDBC=0
      RUN_ODBC=1
      shift
      ;;
    --no-start)
      START_STACK=0
      shift
      ;;
    --no-fixtures)
      LOAD_FIXTURES=0
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
done

[[ -x "${STACK_SCRIPT}" ]] || die "missing stack script: ${STACK_SCRIPT}"
[[ "${MODE}" == "static" || "${MODE}" == "dynamic" ]] || die "--mode must be static or dynamic"
[[ "${IMPORT_BUNDLE}" == "0" || "${IMPORT_BUNDLE}" == "1" ]] || die "--import-bundle must be 0 or 1"
[[ "${RUN_JDBC}" == "1" || "${RUN_ODBC}" == "1" ]] || die "nothing to run (both JDBC and ODBC disabled)"

COMMON_STACK_ARGS=(
  --scratchbird-repo "${SCRATCHBIRD_REPO}"
  --mode "${MODE}"
  --import-bundle "${IMPORT_BUNDLE}"
)

if [[ "${START_STACK}" == "1" ]]; then
  log "starting runtime stack"
  "${STACK_SCRIPT}" up "${COMMON_STACK_ARGS[@]}"
fi

if [[ "${LOAD_FIXTURES}" == "1" ]]; then
  log "loading shared driver fixtures"
  "${STACK_SCRIPT}" fixtures "${COMMON_STACK_ARGS[@]}"
fi

log "loading driver integration environment"
# shellcheck disable=SC2046
eval "$("${STACK_SCRIPT}" env "${COMMON_STACK_ARGS[@]}")"

if [[ "${RUN_JDBC}" == "1" ]]; then
  log "running JDBC test suite"
  (
    cd "${REPO_ROOT}/tracks/p3/drivers/jdbc"
    ./gradlew test
  )
fi

if [[ "${RUN_ODBC}" == "1" ]]; then
  log "configuring ODBC test build"
  cmake -S "${REPO_ROOT}/tracks/p3/drivers/odbc" \
        -B "${REPO_ROOT}/build/odbc-runtime" \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_TESTING=ON \
        -DODBC_FETCH_GTEST=ON

  log "building ODBC test suite"
  cmake --build "${REPO_ROOT}/build/odbc-runtime" --config Release

  log "running ODBC tests (including external runtime connection check)"
  ctest --test-dir "${REPO_ROOT}/build/odbc-runtime" --output-on-failure -R '^scratchbird_odbc_tests$'
fi

log "completed runtime checks"
