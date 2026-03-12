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

resolve_binary() {
  local env_var="$1"
  shift
  local value="${!env_var:-}"
  if [[ -n "${value}" ]]; then
    [[ -x "${value}" ]] || die "${env_var} is set but not executable: ${value}"
    printf '%s\n' "${value}"
    return 0
  fi

  local candidate
  for candidate in "$@"; do
    if [[ -x "${candidate}" ]]; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done
  return 1
}

resolve_example_root() {
  if [[ "${MODE}" == "static" ]]; then
    printf '%s\n' "${SCRATCHBIRD_EXAMPLE_STATIC_ROOT:-${HOME}/.scratchbird/static-example}"
  else
    printf '%s\n' "${SCRATCHBIRD_EXAMPLE_DYNAMIC_ROOT:-/tmp/scratchbird-example-dynamic}"
  fi
}

STACK_ROOT="$(resolve_example_root)"
STACK_CONTROL_DIR="${STACK_ROOT}/control"
STACK_LOG_DIR="${STACK_ROOT}/logs"
STACK_CONFIG_FILE="${STACK_ROOT}/example.conf"
RUNTIME_ENV_FILE="${STACK_ROOT}/profiles/runtime.env"
MANAGER_PORT="${SCRATCHBIRD_DRIVER_MANAGER_PORT:-$([[ "${MODE}" == "static" ]] && printf '13090' || printf '16090')}"
MANAGER_AUTH_TOKEN="${SCRATCHBIRD_DRIVER_MANAGER_AUTH_TOKEN:-token}"
MANAGER_PID_FILE="${STACK_CONTROL_DIR}/sb_manager.pid"
MANAGER_LOG_FILE="${STACK_LOG_DIR}/sb_manager.log"

resolve_manager_binary() {
  resolve_binary SCRATCHBIRD_SB_MANAGER \
    "${SCRATCHBIRD_REPO}/build/src/sb_manager" \
    "${SCRATCHBIRD_REPO}/build/src/network/sb_manager"
}

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

pid_is_running() {
  local pid="$1"
  [[ -n "${pid}" ]] || return 1
  kill -0 "${pid}" 2>/dev/null
}

wait_for_port() {
  local host="$1"
  local port="$2"
  local attempts="${3:-120}"
  local sleep_sec="${4:-0.25}"
  local i
  for ((i = 0; i < attempts; i++)); do
    if (echo > "/dev/tcp/${host}/${port}") >/dev/null 2>&1; then
      return 0
    fi
    sleep "${sleep_sec}"
  done
  return 1
}

stop_manager_proxy() {
  local pid=""
  if [[ -f "${MANAGER_PID_FILE}" ]]; then
    pid="$(tr -d ' \n\r' < "${MANAGER_PID_FILE}")"
  fi

  if [[ -n "${pid}" ]] && pid_is_running "${pid}"; then
    log "stopping manager proxy pid=${pid}"
    kill "${pid}" || true
    local i
    for ((i = 0; i < 40; i++)); do
      if ! pid_is_running "${pid}"; then
        break
      fi
      sleep 0.25
    done
    if pid_is_running "${pid}"; then
      log "forcing manager proxy pid=${pid} to stop"
      kill -9 "${pid}" || true
    fi
  fi

  local manager_bin=""
  manager_bin="$(resolve_manager_binary || true)"
  if [[ -n "${manager_bin}" ]]; then
    local pattern
    pattern="${manager_bin} --bind ${SCRATCHBIRD_NATIVE_HOST:-127.0.0.1} --port ${MANAGER_PORT}"
    local stale_pids=()
    mapfile -t stale_pids < <(pgrep -f -- "${pattern}" || true)
    local stale_pid
    for stale_pid in "${stale_pids[@]}"; do
      if [[ -n "${stale_pid}" ]] && pid_is_running "${stale_pid}"; then
        kill "${stale_pid}" || true
      fi
    done
  fi

  rm -f "${MANAGER_PID_FILE}"
}

start_manager_proxy() {
  require_runtime_env
  load_runtime_env

  local manager_bin
  manager_bin="$(resolve_manager_binary)" || die "sb_manager not found. Build ScratchBird first."

  mkdir -p "${STACK_CONTROL_DIR}" "${STACK_LOG_DIR}"

  if [[ -f "${MANAGER_PID_FILE}" ]]; then
    local existing_pid
    existing_pid="$(tr -d ' \n\r' < "${MANAGER_PID_FILE}")"
    if [[ -n "${existing_pid}" ]] && pid_is_running "${existing_pid}" &&
       wait_for_port "${SCRATCHBIRD_NATIVE_HOST}" "${MANAGER_PORT}" 1 0; then
      return 0
    fi
    stop_manager_proxy
  fi

  : > "${MANAGER_LOG_FILE}"
  setsid -f "${manager_bin}" \
    --bind "${SCRATCHBIRD_NATIVE_HOST}" \
    --port "${MANAGER_PORT}" \
    --native-bind "${SCRATCHBIRD_NATIVE_HOST}" \
    --native-port "${SCRATCHBIRD_NATIVE_PORT}" \
    --database-owner "${SCRATCHBIRD_NATIVE_DB}" \
    --log-level info \
    --mcp-auth-secret "${MANAGER_AUTH_TOKEN}" \
    >> "${MANAGER_LOG_FILE}" 2>&1 < /dev/null

  local manager_pattern
  manager_pattern="${manager_bin} --bind ${SCRATCHBIRD_NATIVE_HOST} --port ${MANAGER_PORT}"
  local manager_pid=""
  local i
  for ((i = 0; i < 40; i++)); do
    manager_pid="$(pgrep -f -- "${manager_pattern}" | head -n 1 || true)"
    if [[ -n "${manager_pid}" ]]; then
      break
    fi
    sleep 0.25
  done

  [[ -n "${manager_pid}" ]] || die "manager proxy started but pid could not be discovered"
  printf '%s\n' "${manager_pid}" > "${MANAGER_PID_FILE}"

  if ! wait_for_port "${SCRATCHBIRD_NATIVE_HOST}" "${MANAGER_PORT}" 120 0.25; then
    tail -n 100 "${MANAGER_LOG_FILE}" >&2 || true
    die "manager proxy failed to come up on ${SCRATCHBIRD_NATIVE_HOST}:${MANAGER_PORT}"
  fi
}

print_manager_status() {
  local state="down"
  local pid=""
  if [[ -f "${MANAGER_PID_FILE}" ]]; then
    pid="$(tr -d ' \n\r' < "${MANAGER_PID_FILE}")"
    if [[ -n "${pid}" ]] && pid_is_running "${pid}"; then
      state="running pid=${pid}"
    fi
  fi
  log "manager_proxy=${state} port=${MANAGER_PORT}"
}

emit_driver_env() {
  require_runtime_env
  load_runtime_env

  local native_sslmode
  native_sslmode="${SCRATCHBIRD_NATIVE_SSLMODE:-disable}"
  local native_url
  native_url="scratchbird://${SCRATCHBIRD_NATIVE_USER}:${SCRATCHBIRD_NATIVE_PASSWORD}@${SCRATCHBIRD_NATIVE_HOST}:${SCRATCHBIRD_NATIVE_PORT}/${SCRATCHBIRD_NATIVE_DB}?sslmode=${native_sslmode}"
  local manager_url
  manager_url="scratchbird://${SCRATCHBIRD_NATIVE_USER}:${SCRATCHBIRD_NATIVE_PASSWORD}@${SCRATCHBIRD_NATIVE_HOST}:${MANAGER_PORT}/${SCRATCHBIRD_NATIVE_DB}?sslmode=${native_sslmode}&front_door_mode=manager_proxy&manager_auth_token=${MANAGER_AUTH_TOKEN}"
  local jdbc_url
  jdbc_url="jdbc:scratchbird://${SCRATCHBIRD_NATIVE_HOST}:${SCRATCHBIRD_NATIVE_PORT}/${SCRATCHBIRD_NATIVE_DB}?sslmode=${native_sslmode}"
  local jdbc_manager_url
  jdbc_manager_url="jdbc:scratchbird://${SCRATCHBIRD_NATIVE_HOST}:${MANAGER_PORT}/${SCRATCHBIRD_NATIVE_DB}?sslmode=${native_sslmode}&front_door_mode=manager_proxy&manager_auth_token=${MANAGER_AUTH_TOKEN}"
  local dotnet_url
  dotnet_url="${native_url}"
  if [[ "${native_sslmode}" == "disable" ]]; then
    dotnet_url="${dotnet_url}&allow_insecure=true"
  fi
  local dotnet_manager_url
  dotnet_manager_url="${manager_url}"
  if [[ "${native_sslmode}" == "disable" ]]; then
    dotnet_manager_url="${dotnet_manager_url}&allow_insecure=true"
  fi
  local odbc_conn
  odbc_conn="Driver={ScratchBird};Server=${SCRATCHBIRD_NATIVE_HOST};Port=${SCRATCHBIRD_NATIVE_PORT};Database=${SCRATCHBIRD_NATIVE_DB};UID=${SCRATCHBIRD_NATIVE_USER};PWD=${SCRATCHBIRD_NATIVE_PASSWORD};SSLMode=${native_sslmode}"
  local odbc_manager_conn
  odbc_manager_conn="Driver={ScratchBird};Server=${SCRATCHBIRD_NATIVE_HOST};Port=${MANAGER_PORT};Database=${SCRATCHBIRD_NATIVE_DB};UID=${SCRATCHBIRD_NATIVE_USER};PWD=${SCRATCHBIRD_NATIVE_PASSWORD};SSLMode=${native_sslmode};FrontDoorMode=manager_proxy;ManagerAuthToken=${MANAGER_AUTH_TOKEN}"
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
export SCRATCHBIRD_TEST_MANAGER_DSN='${manager_url}'
export SCRATCHBIRD_GO_MANAGER_URL='${manager_url}'
export SCRATCHBIRD_NODE_MANAGER_URL='${manager_url}'
export SCRATCHBIRD_RUST_MANAGER_URL='${manager_url}'
export SCRATCHBIRD_RUBY_MANAGER_URL='${manager_url}'
export SCRATCHBIRD_PHP_MANAGER_URL='${manager_url}'
export SCRATCHBIRD_DOTNET_MANAGER_URL='${dotnet_manager_url}'
export SCRATCHBIRD_R_MANAGER_URL='${manager_url}'
export SCRATCHBIRD_PASCAL_MANAGER_URL='${manager_url}'
export SCRATCHBIRD_MOJO_MANAGER_URL='${manager_url}'

export SCRATCHBIRD_JDBC_URL='${jdbc_url}'
export SCRATCHBIRD_JDBC_MANAGER_URL='${jdbc_manager_url}'
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
export SCRATCHBIRD_ODBC_MANAGER_CONNSTR='${odbc_manager_conn}'
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
  "${SCRATCHBIRD_SB_ISQL}" "${common_args[@]}" -c "DROP TABLE IF EXISTS generated_key_fixture;"

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
    start_manager_proxy
    ;;
  down)
    log "stopping ${MODE} runtime stack"
    stop_manager_proxy
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
    print_manager_status
    ;;
  refresh)
    [[ "${MODE}" == "static" ]] || die "refresh is only available in static mode"
    log "refreshing static runtime stack"
    run_manager "static-refresh"
    start_manager_proxy
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
