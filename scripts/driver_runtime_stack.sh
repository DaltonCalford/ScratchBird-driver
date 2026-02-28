#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

SCRATCHBIRD_REPO="${SCRATCHBIRD_REPO:-${REPO_ROOT}/../ScratchBird}"
MODE="${SB_DRIVER_STACK_MODE:-static}"
IMPORT_BUNDLE="${SB_DRIVER_IMPORT_BUNDLE:-0}"

FIXTURE_CORE="${REPO_ROOT}/docs/fixtures/core_fixture.sql"
FIXTURE_TYPES="${REPO_ROOT}/docs/fixtures/types_fixture.sql"

COMMAND="${1:-help}"
if [[ $# -gt 0 ]]; then
  shift
fi

usage() {
  cat <<'USAGE'
Usage: scripts/driver_runtime_stack.sh <command> [options]

Commands:
  up           Start ScratchBird runtime stack for driver integration
  down         Stop runtime stack
  status       Show runtime status
  refresh      Recreate static stack and reseed
  env          Print driver integration environment exports
  fixtures     Load shared driver fixtures into native DB

Options:
  --scratchbird-repo <path>   ScratchBird repo root (default: ../ScratchBird)
  --mode <static|dynamic>     Stack mode (default: static)
  --import-bundle <0|1>       Import large example bundle on setup (default: 0)
  --help                      Show help

Examples:
  scripts/driver_runtime_stack.sh up
  eval "$(scripts/driver_runtime_stack.sh env)"
  scripts/driver_runtime_stack.sh fixtures
USAGE
}

log() {
  printf '[driver-stack] %s\n' "$*"
}

die() {
  printf '[driver-stack] error: %s\n' "$*" >&2
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
    --help|-h)
      usage
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
done

[[ "${MODE}" == "static" || "${MODE}" == "dynamic" ]] || die "--mode must be static or dynamic"
[[ "${IMPORT_BUNDLE}" == "0" || "${IMPORT_BUNDLE}" == "1" ]] || die "--import-bundle must be 0 or 1"

MANAGER_SCRIPT="${SCRATCHBIRD_REPO}/scripts/example_db_manager.sh"
[[ -x "${MANAGER_SCRIPT}" ]] || die "example manager not found: ${MANAGER_SCRIPT}"

resolve_example_root() {
  if [[ "${MODE}" == "static" ]]; then
    printf '%s\n' "${SCRATCHBIRD_EXAMPLE_STATIC_ROOT:-${HOME}/.scratchbird/static-example}"
  else
    printf '%s\n' "${SCRATCHBIRD_EXAMPLE_DYNAMIC_ROOT:-/tmp/scratchbird-example-dynamic}"
  fi
}

RUNTIME_ENV_FILE="$(resolve_example_root)/profiles/runtime.env"

run_manager() {
  local action="$1"
  SCRATCHBIRD_EXAMPLE_IMPORT_BUNDLE="${IMPORT_BUNDLE}" \
  SCRATCHBIRD_EXAMPLE_AUTH_METHODS="${SCRATCHBIRD_DRIVER_AUTH_METHODS:-trust,password}" \
  SCRATCHBIRD_EXAMPLE_NATIVE_FORCE_PASSWORD_AUTH="${SCRATCHBIRD_DRIVER_FORCE_PASSWORD_AUTH:-0}" \
  "${MANAGER_SCRIPT}" "${action}"
}

require_runtime_env() {
  [[ -f "${RUNTIME_ENV_FILE}" ]] || die "runtime profile missing: ${RUNTIME_ENV_FILE}. Run '$0 up' first."
}

load_runtime_env() {
  # shellcheck disable=SC1090
  source "${RUNTIME_ENV_FILE}"
}

emit_driver_env() {
  require_runtime_env
  load_runtime_env

  local native_sslmode
  native_sslmode="${SCRATCHBIRD_NATIVE_SSLMODE:-disable}"
  local native_url
  native_url="scratchbird://${SCRATCHBIRD_NATIVE_USER}:${SCRATCHBIRD_NATIVE_PASSWORD}@${SCRATCHBIRD_NATIVE_HOST}:${SCRATCHBIRD_NATIVE_PORT}/${SCRATCHBIRD_NATIVE_DB}?sslmode=${native_sslmode}"
  local jdbc_url
  jdbc_url="jdbc:scratchbird://${SCRATCHBIRD_NATIVE_HOST}:${SCRATCHBIRD_NATIVE_PORT}/${SCRATCHBIRD_NATIVE_DB}?sslmode=${native_sslmode}"
  local dotnet_url
  dotnet_url="${native_url}"
  if [[ "${native_sslmode}" == "disable" ]]; then
    dotnet_url="${dotnet_url}&allow_insecure=true"
  fi
  local odbc_conn
  odbc_conn="Driver={ScratchBird};Server=${SCRATCHBIRD_NATIVE_HOST};Port=${SCRATCHBIRD_NATIVE_PORT};Database=${SCRATCHBIRD_NATIVE_DB};UID=${SCRATCHBIRD_NATIVE_USER};PWD=${SCRATCHBIRD_NATIVE_PASSWORD};SSLMode=${native_sslmode}"
  local cancel_sql
  cancel_sql="${SCRATCHBIRD_DRIVER_CANCEL_SQL:-SELECT pg_sleep(5)}"
  local escaped_cancel_sql
  escaped_cancel_sql="${cancel_sql//\'/\'\"\'\"\'}"

  cat <<EOF
export SCRATCHBIRD_TEST_DSN='${native_url}'
export SCRATCHBIRD_GO_URL='${native_url}'
export SCRATCHBIRD_NODE_URL='${native_url}'
export SCRATCHBIRD_RUST_URL='${native_url}'
export SCRATCHBIRD_RUBY_URL='${native_url}'
export SCRATCHBIRD_PHP_URL='${native_url}'
export SCRATCHBIRD_DOTNET_URL='${dotnet_url}'
export SCRATCHBIRD_R_URL='${native_url}'
export SCRATCHBIRD_PASCAL_URL='${native_url}'
export SCRATCHBIRD_MOJO_URL='${native_url}'

export SCRATCHBIRD_JDBC_URL='${jdbc_url}'
export SCRATCHBIRD_JDBC_USER='${SCRATCHBIRD_NATIVE_USER}'
export SCRATCHBIRD_JDBC_PASSWORD='${SCRATCHBIRD_NATIVE_PASSWORD}'
export SCRATCHBIRD_JDBC_CANCEL_SQL='${escaped_cancel_sql}'

export SCRATCHBIRD_TEST_CANCEL_SQL='${escaped_cancel_sql}'
export SCRATCHBIRD_GO_CANCEL_SQL='${escaped_cancel_sql}'
export SCRATCHBIRD_NODE_CANCEL_SQL='${escaped_cancel_sql}'
export SCRATCHBIRD_RUST_CANCEL_SQL='${escaped_cancel_sql}'
export SCRATCHBIRD_RUBY_CANCEL_SQL='${escaped_cancel_sql}'
export SCRATCHBIRD_PHP_CANCEL_SQL='${escaped_cancel_sql}'
export SCRATCHBIRD_DOTNET_CANCEL_SQL='${escaped_cancel_sql}'
export SCRATCHBIRD_R_CANCEL_SQL='${escaped_cancel_sql}'
export SCRATCHBIRD_PASCAL_CANCEL_SQL='${escaped_cancel_sql}'
export SCRATCHBIRD_MOJO_CANCEL_SQL='${escaped_cancel_sql}'

export SCRATCHBIRD_ODBC_TEST_CONNSTR='${odbc_conn}'
EOF
}

load_fixtures() {
  require_runtime_env
  load_runtime_env

  [[ -x "${SCRATCHBIRD_SB_ISQL:-}" ]] || die "sb_isql missing/executable not found: ${SCRATCHBIRD_SB_ISQL:-<unset>}"
  [[ -f "${FIXTURE_CORE}" ]] || die "missing fixture file: ${FIXTURE_CORE}"
  [[ -f "${FIXTURE_TYPES}" ]] || die "missing fixture file: ${FIXTURE_TYPES}"

  local native_sslmode="${SCRATCHBIRD_NATIVE_SSLMODE:-disable}"
  local common_args=(
    "-H" "${SCRATCHBIRD_NATIVE_HOST}"
    "-p" "${SCRATCHBIRD_NATIVE_PORT}"
    "-U" "${SCRATCHBIRD_NATIVE_USER}"
    "-P" "${SCRATCHBIRD_NATIVE_PASSWORD}"
    "--sslmode=${native_sslmode}"
    "${SCRATCHBIRD_NATIVE_DB}"
  )

  log "resetting driver fixture tables"
  "${SCRATCHBIRD_SB_ISQL}" "${common_args[@]}" -c "DROP TABLE IF EXISTS type_coverage;"
  "${SCRATCHBIRD_SB_ISQL}" "${common_args[@]}" -c "DROP TABLE IF EXISTS basic_table;"

  log "loading core fixture: ${FIXTURE_CORE}"
  "${SCRATCHBIRD_SB_ISQL}" "${common_args[@]}" -f "${FIXTURE_CORE}"

  log "loading types fixture: ${FIXTURE_TYPES}"
  "${SCRATCHBIRD_SB_ISQL}" "${common_args[@]}" -f "${FIXTURE_TYPES}"
}

case "${COMMAND}" in
  up)
    log "starting ${MODE} runtime stack"
    if [[ "${MODE}" == "static" ]]; then
      run_manager "static-up"
    else
      run_manager "dynamic-setup"
    fi
    ;;
  down)
    log "stopping ${MODE} runtime stack"
    if [[ "${MODE}" == "static" ]]; then
      run_manager "static-down"
    else
      run_manager "dynamic-teardown"
    fi
    ;;
  status)
    if [[ "${MODE}" == "static" ]]; then
      run_manager "static-status"
    else
      run_manager "dynamic-status"
    fi
    ;;
  refresh)
    [[ "${MODE}" == "static" ]] || die "refresh is only available in static mode"
    log "refreshing static runtime stack"
    run_manager "static-refresh"
    ;;
  env)
    emit_driver_env
    ;;
  fixtures)
    load_fixtures
    ;;
  help|--help|-h)
    usage
    ;;
  *)
    die "unknown command: ${COMMAND}"
    ;;
esac
