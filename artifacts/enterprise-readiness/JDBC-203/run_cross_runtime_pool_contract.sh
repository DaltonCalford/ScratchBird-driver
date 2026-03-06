#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUTDIR="${ROOT_DIR}/artifacts/enterprise-readiness/JDBC-203"
mkdir -p "$OUTDIR"
LOG_FILE="$OUTDIR/contract_run_${TIMESTAMP}.log"
SUMMARY_FILE="$OUTDIR/contract_gate_summary_${TIMESTAMP}.json"
LATEST_LOG="$OUTDIR/latest_verification.log"
LATEST_SUMMARY="$OUTDIR/latest_contract_summary.json"

exec > >(tee "$LOG_FILE") 2>&1

strict_gate="${JDBC203_STRICT_GATE:-${GITHUB_ACTIONS:-false}}"
strict_gate="${strict_gate,,}"

profiles_input="${JDBC203_PROFILES:-direct}"
if [[ -z "${JDBC203_PROFILES:-}" ]]; then
  if [[ -n "${SCRATCHBIRD_DOTNET_MANAGER_URL:-}" || -n "${SCRATCHBIRD_JDBC_MANAGER_URL:-}" ]]; then
    profiles_input+=" ,manager"
  fi
  if [[ -n "${SCRATCHBIRD_DOTNET_LISTENER_URL:-}" || -n "${SCRATCHBIRD_JDBC_LISTENER_URL:-}" ]]; then
    profiles_input+=" ,listener"
  fi
fi

required_env=()
profile_order=()
declare -A dotnet_profile_status=()
declare -A jdbc_profile_status=()
release_freeze_reasons=()

dotnet_status="not_run"
jdbc_status="not_run"
overall_status="partial"
reason="runtime_tests_executed_with_expected_skips"
release_freeze="false"
exit_code=0

trim() {
  local value="$1"
  # shellcheck disable=SC2001
  value="$(echo "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  printf '%s' "$value"
}

normalize_profiles() {
  local raw="${profiles_input//,/ }"
  local token
  for token in $raw; do
    token="$(trim "${token,,}")"
    [[ -z "$token" ]] && continue
    case "$token" in
      direct|manager|listener)
        ;;
      *)
        echo "[warn] ignoring unsupported profile '$token' (supported: direct, manager, listener)"
        continue
        ;;
    esac

    local exists="false"
    local existing
    for existing in "${profile_order[@]:-}"; do
      if [[ "$existing" == "$token" ]]; then
        exists="true"
        break
      fi
    done
    if [[ "$exists" == "false" ]]; then
      profile_order+=("$token")
    fi
  done

  if (( ${#profile_order[@]} == 0 )); then
    profile_order=("direct")
  fi
}

profile_dotnet_url() {
  local profile="$1"
  case "$profile" in
    direct)
      printf '%s' "${SCRATCHBIRD_DOTNET_URL:-}"
      ;;
    manager)
      printf '%s' "${SCRATCHBIRD_DOTNET_MANAGER_URL:-}"
      ;;
    listener)
      printf '%s' "${SCRATCHBIRD_DOTNET_LISTENER_URL:-}"
      ;;
  esac
}

profile_jdbc_url() {
  local profile="$1"
  case "$profile" in
    direct)
      printf '%s' "${SCRATCHBIRD_JDBC_URL:-}"
      ;;
    manager)
      printf '%s' "${SCRATCHBIRD_JDBC_MANAGER_URL:-}"
      ;;
    listener)
      printf '%s' "${SCRATCHBIRD_JDBC_LISTENER_URL:-}"
      ;;
  esac
}

profile_dotnet_cancel_sql() {
  local profile="$1"
  case "$profile" in
    direct)
      printf '%s' "${SCRATCHBIRD_DOTNET_CANCEL_SQL:-}"
      ;;
    manager)
      if [[ -n "${SCRATCHBIRD_DOTNET_MANAGER_CANCEL_SQL:-}" ]]; then
        printf '%s' "${SCRATCHBIRD_DOTNET_MANAGER_CANCEL_SQL}"
      else
        printf '%s' "${SCRATCHBIRD_DOTNET_CANCEL_SQL:-}"
      fi
      ;;
    listener)
      if [[ -n "${SCRATCHBIRD_DOTNET_LISTENER_CANCEL_SQL:-}" ]]; then
        printf '%s' "${SCRATCHBIRD_DOTNET_LISTENER_CANCEL_SQL}"
      else
        printf '%s' "${SCRATCHBIRD_DOTNET_CANCEL_SQL:-}"
      fi
      ;;
  esac
}

profile_jdbc_cancel_sql() {
  local profile="$1"
  case "$profile" in
    direct)
      printf '%s' "${SCRATCHBIRD_JDBC_CANCEL_SQL:-}"
      ;;
    manager)
      if [[ -n "${SCRATCHBIRD_JDBC_MANAGER_CANCEL_SQL:-}" ]]; then
        printf '%s' "${SCRATCHBIRD_JDBC_MANAGER_CANCEL_SQL}"
      else
        printf '%s' "${SCRATCHBIRD_JDBC_CANCEL_SQL:-}"
      fi
      ;;
    listener)
      if [[ -n "${SCRATCHBIRD_JDBC_LISTENER_CANCEL_SQL:-}" ]]; then
        printf '%s' "${SCRATCHBIRD_JDBC_LISTENER_CANCEL_SQL}"
      else
        printf '%s' "${SCRATCHBIRD_JDBC_CANCEL_SQL:-}"
      fi
      ;;
  esac
}

refresh_required_env() {
  required_env=()
  local profile
  for profile in "${profile_order[@]}"; do
    local dotnet_url jdbc_url dotnet_cancel jdbc_cancel
    dotnet_url="$(profile_dotnet_url "$profile")"
    jdbc_url="$(profile_jdbc_url "$profile")"
    dotnet_cancel="$(profile_dotnet_cancel_sql "$profile")"
    jdbc_cancel="$(profile_jdbc_cancel_sql "$profile")"

    if [[ -z "$dotnet_url" ]]; then
      required_env+=("${profile^^}_SCRATCHBIRD_DOTNET_URL")
    fi
    if [[ -z "$jdbc_url" ]]; then
      required_env+=("${profile^^}_SCRATCHBIRD_JDBC_URL")
    fi
    if [[ -z "$dotnet_cancel" ]]; then
      required_env+=("${profile^^}_SCRATCHBIRD_DOTNET_CANCEL_SQL")
    fi
    if [[ -z "$jdbc_cancel" ]]; then
      required_env+=("${profile^^}_SCRATCHBIRD_JDBC_CANCEL_SQL")
    fi
  done
}

required_env_json() {
  local missing_env_json="[]"
  if (( ${#required_env[@]} > 0 )); then
    missing_env_json='['
    local env_name
    for env_name in "${required_env[@]}"; do
      if [[ "$missing_env_json" != "[" ]]; then
        missing_env_json+=","
      fi
      missing_env_json+="\"${env_name}\""
    done
    missing_env_json+="]"
  fi
  printf '%s' "$missing_env_json"
}

attempt_runtime_env_autoload() {
  refresh_required_env
  if (( ${#required_env[@]} == 0 )); then
    return 0
  fi
  if [[ ! -x "$ROOT_DIR/scripts/driver_runtime_stack.sh" ]]; then
    return 1
  fi

  echo "[info] runtime env incomplete; attempting static runtime refresh"
  set +e
  "$ROOT_DIR/scripts/driver_runtime_stack.sh" refresh --mode static >/dev/null 2>&1
  local refresh_rc=$?
  set -e
  if [[ "$refresh_rc" -ne 0 ]]; then
    echo "[warn] runtime stack refresh failed; continuing with current environment"
    return 1
  fi

  set +e
  # shellcheck disable=SC1090
  eval "$($ROOT_DIR/scripts/driver_runtime_stack.sh env --mode static)"
  local env_rc=$?
  set -e
  if [[ "$env_rc" -ne 0 ]]; then
    echo "[warn] runtime stack env export failed; continuing with current environment"
    return 1
  fi
  return 0
}

validate_dotnet_url() {
  local url="$1"
  local normalized="$url"
  if [[ "$normalized" == sb://* ]]; then
    normalized="scratchbird://${normalized#sb://}"
    echo "[warn] normalized .NET URL from sb:// to scratchbird://"
  fi
  if [[ "$normalized" == *"://"* && "${normalized%%://*}" != "scratchbird" ]]; then
    return 1
  fi
  printf '%s' "$normalized"
}

validate_jdbc_url() {
  local url="$1"
  [[ "$url" == jdbc:scratchbird:* ]]
}

dotnet_contract_tests=(
  "ScratchBird.Data.Tests.JDBC203PoolingAndRecoveryContractTests.ScenarioA_BorrowReuseAfterExplicitCancel"
  "ScratchBird.Data.Tests.JDBC203PoolingAndRecoveryContractTests.ScenarioB_TimeoutCancellationReuse"
  "ScratchBird.Data.Tests.JDBC203PoolingAndRecoveryContractTests.ScenarioC_ConcurrentPoolStress10Workers"
  "ScratchBird.Data.Tests.JDBC203PoolingAndRecoveryContractTests.ScenarioD_ReconnectRecoveryAfterFailure"
  "ScratchBird.Data.Tests.JDBC203PoolingAndRecoveryContractTests.ScenarioE_MetadataAndStreamReuseAfterRecovery"
)

run_dotnet_contract_phase() {
  local profile="$1"
  local project_path="$ROOT_DIR/tracks/alpha/drivers/dotnet/tests/ScratchBird.Data.Tests/ScratchBird.Data.Tests.csproj"
  local first_run="true"
  local failures=0
  local idx=0
  local test_name

  for test_name in "${dotnet_contract_tests[@]}"; do
    idx=$((idx + 1))
    echo "[step] [.NET][$profile] pooling case ${idx}/${#dotnet_contract_tests[@]}: ${test_name}"

    if [[ -x "$ROOT_DIR/scripts/driver_runtime_stack.sh" ]]; then
      set +e
      "$ROOT_DIR/scripts/driver_runtime_stack.sh" refresh --mode static >/dev/null 2>&1
      local refresh_rc=$?
      set -e
      if [[ "$refresh_rc" -eq 0 ]]; then
        set +e
        # shellcheck disable=SC1090
        eval "$($ROOT_DIR/scripts/driver_runtime_stack.sh env --mode static)"
        local env_rc=$?
        set -e
        if [[ "$env_rc" -ne 0 ]]; then
          echo "[warn] failed to load refreshed runtime env before ${test_name}; continuing with current environment"
        fi
      else
        echo "[warn] runtime stack refresh failed before ${test_name}; continuing with current environment"
      fi
    fi

    local args=(
      dotnet test "$project_path"
      --filter "FullyQualifiedName=${test_name}"
      -l "trx;LogFileName=artifacts/enterprise-readiness/JDBC-203/dotnet_pooling_contract_${profile}_case_${idx}.trx"
    )
    if [[ "$first_run" == "false" ]]; then
      args+=(--no-build)
    fi

    set +e
    (cd "$ROOT_DIR" && "${args[@]}")
    local case_rc=$?
    set -e
    if [[ "$case_rc" -ne 0 ]]; then
      failures=$((failures + 1))
      echo "[fail] [.NET][$profile] pooling case failed: ${test_name} (exit=${case_rc})"
    fi
    first_run="false"
  done

  [[ "$failures" -eq 0 ]]
}

run_jdbc_contract_phase() {
  local profile="$1"
  echo "[step] [JDBC][$profile] pooling phase"
  set +e
  (
    cd "$ROOT_DIR/tracks/alpha/drivers/jdbc"
    ./gradlew test --tests "com.scratchbird.jdbc.JDBC203PoolingAndRecoveryContractTest" \
      -Dorg.gradle.warning.mode=none
  )
  local rc=$?
  set -e
  return "$rc"
}

profile_json() {
  local json='['
  local profile
  for profile in "${profile_order[@]}"; do
    if [[ "$json" != "[" ]]; then
      json+=","
    fi
    json+="{\"name\":\"${profile}\",\"dotnet\":\"${dotnet_profile_status[$profile]:-not_run}\",\"jdbc\":\"${jdbc_profile_status[$profile]:-not_run}\"}"
  done
  json+=']'
  printf '%s' "$json"
}

write_summary() {
  local summary_file="$1"
  refresh_required_env
  local missing_env_json
  missing_env_json="$(required_env_json)"

  local freeze_reasons_json="[]"
  if (( ${#release_freeze_reasons[@]} > 0 )); then
    freeze_reasons_json='['
    local freeze_reason
    for freeze_reason in "${release_freeze_reasons[@]}"; do
      if [[ "$freeze_reasons_json" != "[" ]]; then
        freeze_reasons_json+=","
      fi
      freeze_reasons_json+="\"${freeze_reason}\""
    done
    freeze_reasons_json+="]"
  fi

  cat > "$summary_file" <<JSON
{
  "timestamp": "$TIMESTAMP",
  "strictGate": "$strict_gate",
  "profiles": $(profile_json),
  "dotnet": {
    "status": "$dotnet_status"
  },
  "jdbc": {
    "status": "$jdbc_status"
  },
  "overallStatus": "$overall_status",
  "reason": "$reason",
  "missingEnv": $missing_env_json,
  "releaseFreeze": {
    "active": $release_freeze,
    "reasons": $freeze_reasons_json
  }
}
JSON
}

finalize() {
  write_summary "$SUMMARY_FILE"
  cp "$SUMMARY_FILE" "$LATEST_SUMMARY"
  cp "$LOG_FILE" "$LATEST_LOG"
}

normalize_profiles

echo "JDBC-203 cross-runtime pooling contract run"
echo "timestamp: $TIMESTAMP"
echo "root: $ROOT_DIR"
echo "strict_gate: $strict_gate"
echo "profiles: ${profile_order[*]}"
echo

attempt_runtime_env_autoload || true
refresh_required_env

for profile in "${profile_order[@]}"; do
  dotnet_profile_status[$profile]="not_run"
  jdbc_profile_status[$profile]="not_run"

  dotnet_url="$(profile_dotnet_url "$profile")"
  jdbc_url="$(profile_jdbc_url "$profile")"
  dotnet_cancel_sql="$(profile_dotnet_cancel_sql "$profile")"
  jdbc_cancel_sql="$(profile_jdbc_cancel_sql "$profile")"

  if [[ -z "$dotnet_url" || -z "$jdbc_url" || -z "$dotnet_cancel_sql" || -z "$jdbc_cancel_sql" ]]; then
    echo "[warn] [$profile] missing one or more required runtime/cancel env values"
    dotnet_profile_status[$profile]="env_missing"
    jdbc_profile_status[$profile]="env_missing"
    continue
  fi

  set +e
  normalized_dotnet_url="$(validate_dotnet_url "$dotnet_url")"
  normalize_rc=$?
  set -e
  if [[ "$normalize_rc" -ne 0 ]]; then
    echo "[warn] [$profile] invalid .NET URL scheme in '$dotnet_url'"
    dotnet_profile_status[$profile]="failed"
    jdbc_profile_status[$profile]="not_run"
    release_freeze="true"
    release_freeze_reasons+=("dotnet_contract_failed_${profile}")
    continue
  fi

  if ! validate_jdbc_url "$jdbc_url"; then
    echo "[warn] [$profile] JDBC URL must start with jdbc:scratchbird: (got '$jdbc_url')"
    dotnet_profile_status[$profile]="not_run"
    jdbc_profile_status[$profile]="failed"
    release_freeze="true"
    release_freeze_reasons+=("jdbc_contract_failed_${profile}")
    continue
  fi

  export SCRATCHBIRD_DOTNET_URL="$normalized_dotnet_url"
  export SCRATCHBIRD_DOTNET_CANCEL_SQL="$dotnet_cancel_sql"
  export SCRATCHBIRD_JDBC_URL="$jdbc_url"
  export SCRATCHBIRD_JDBC_CANCEL_SQL="$jdbc_cancel_sql"

  echo "[info] [$profile] running with .NET URL: $SCRATCHBIRD_DOTNET_URL"
  echo "[info] [$profile] running with JDBC URL: $SCRATCHBIRD_JDBC_URL"

  if run_dotnet_contract_phase "$profile"; then
    dotnet_profile_status[$profile]="passed"
  else
    dotnet_profile_status[$profile]="failed"
    release_freeze="true"
    release_freeze_reasons+=("dotnet_contract_failed_${profile}")
  fi

  if run_jdbc_contract_phase "$profile"; then
    jdbc_profile_status[$profile]="passed"
  else
    jdbc_profile_status[$profile]="failed"
    release_freeze="true"
    release_freeze_reasons+=("jdbc_contract_failed_${profile}")
  fi

done

any_failed="false"
any_missing="false"
all_passed="true"

for profile in "${profile_order[@]}"; do
  case "${dotnet_profile_status[$profile]}" in
    failed) any_failed="true"; all_passed="false" ;;
    env_missing|not_run) any_missing="true"; all_passed="false" ;;
    passed) ;;
    *) all_passed="false" ;;
  esac
  case "${jdbc_profile_status[$profile]}" in
    failed) any_failed="true"; all_passed="false" ;;
    env_missing|not_run) any_missing="true"; all_passed="false" ;;
    passed) ;;
    *) all_passed="false" ;;
  esac
done

if [[ "$all_passed" == "true" ]]; then
  dotnet_status="passed"
  jdbc_status="passed"
  overall_status="pass"
  reason="both_runtimes_executed"
  echo "[pass] all profiles passed for both runtimes"
elif [[ "$any_failed" == "true" ]]; then
  dotnet_status="failed"
  jdbc_status="failed"
  overall_status="failed"
  reason="runtime_contract_failure"
  release_freeze="true"
  release_freeze_reasons+=("runtime_contract_failure")
  exit_code=1
  echo "[fail] one or more profiles failed"
else
  dotnet_status="env_missing"
  jdbc_status="env_missing"
  overall_status="blocked"
  if [[ "$strict_gate" == "true" || "$strict_gate" == "1" ]]; then
    reason="strict_gate_missing_env"
    release_freeze="true"
    release_freeze_reasons+=("strict_gate_missing_env")
    exit_code=1
  else
    reason="missing_env_for_full_cross_runtime_contract"
    echo "[warn] profiles skipped due missing env while strict gate is disabled"
  fi
fi

finalize
exit "$exit_code"
