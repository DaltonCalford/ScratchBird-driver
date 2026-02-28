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

required_env=()

refresh_required_env() {
  required_env=()
  if [[ -z "${SCRATCHBIRD_DOTNET_URL:-}" ]]; then
    required_env+=("SCRATCHBIRD_DOTNET_URL")
  fi
  if [[ -z "${SCRATCHBIRD_DOTNET_CANCEL_SQL:-}" ]]; then
    required_env+=("SCRATCHBIRD_DOTNET_CANCEL_SQL")
  fi
}

required_env_json() {
  local missing_env_json="[]"
  if (( ${#required_env[@]} > 0 )); then
    missing_env_json='['
    local env_name
    for env_name in "${required_env[@]}"; do
      if [[ "${missing_env_json}" != "[" ]]; then
        missing_env_json+=","
      fi
      missing_env_json+="\"${env_name}\""
    done
    missing_env_json+="]"
  fi
  printf '%s' "${missing_env_json}"
}

attempt_dotnet_env_autoload() {
  if [[ -n "${SCRATCHBIRD_DOTNET_URL:-}" && -n "${SCRATCHBIRD_DOTNET_CANCEL_SQL:-}" ]]; then
    return 0
  fi
  if [[ ! -x "$ROOT_DIR/scripts/driver_runtime_stack.sh" ]]; then
    return 1
  fi

  echo "[info] SCRATCHBIRD_DOTNET_* not fully set; attempting static runtime refresh"
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
  eval "$("$ROOT_DIR/scripts/driver_runtime_stack.sh" env --mode static)"
  local env_rc=$?
  set -e
  if [[ "$env_rc" -ne 0 ]]; then
    echo "[warn] runtime stack env export failed; continuing with current environment"
    return 1
  fi
  return 0
}

refresh_required_env

strict_gate="${JDBC203_STRICT_GATE:-${GITHUB_ACTIONS:-false}}"
strict_gate="${strict_gate,,}"

dotnet_status="not_run"
jdbc_status="not_run"
release_freeze="false"
release_freeze_reasons=()
overall_status="partial"
reason="runtime_tests_executed_with_expected_skips"
exit_code=0

dotnet_contract_tests=(
  "ScratchBird.Data.Tests.JDBC203PoolingAndRecoveryContractTests.ScenarioA_BorrowReuseAfterExplicitCancel"
  "ScratchBird.Data.Tests.JDBC203PoolingAndRecoveryContractTests.ScenarioB_TimeoutCancellationReuse"
  "ScratchBird.Data.Tests.JDBC203PoolingAndRecoveryContractTests.ScenarioC_ConcurrentPoolStress10Workers"
  "ScratchBird.Data.Tests.JDBC203PoolingAndRecoveryContractTests.ScenarioD_ReconnectRecoveryAfterFailure"
  "ScratchBird.Data.Tests.JDBC203PoolingAndRecoveryContractTests.ScenarioE_MetadataAndStreamReuseAfterRecovery"
)

run_dotnet_contract_phase() {
  local project_path="$ROOT_DIR/tracks/alpha/drivers/dotnet/tests/ScratchBird.Data.Tests/ScratchBird.Data.Tests.csproj"
  local first_run="true"
  local failures=0
  local idx=0

  for test_name in "${dotnet_contract_tests[@]}"; do
    idx=$((idx + 1))
    echo "[step] .NET pooling case ${idx}/${#dotnet_contract_tests[@]}: ${test_name}"

    if [[ -x "$ROOT_DIR/scripts/driver_runtime_stack.sh" ]]; then
      set +e
      "$ROOT_DIR/scripts/driver_runtime_stack.sh" refresh --mode static >/dev/null 2>&1
      local refresh_rc=$?
      set -e
      if [[ "$refresh_rc" -eq 0 ]]; then
        set +e
        # shellcheck disable=SC1090
        eval "$("$ROOT_DIR/scripts/driver_runtime_stack.sh" env --mode static)"
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
      -l "trx;LogFileName=artifacts/enterprise-readiness/JDBC-203/dotnet_pooling_contract_case_${idx}.trx"
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
      echo "[fail] .NET pooling case failed: ${test_name} (exit=${case_rc})"
    fi
    first_run="false"
  done

  if [[ "$failures" -ne 0 ]]; then
    return 1
  fi
  return 0
}

write_summary() {
  local summary_file="$1"
  refresh_required_env
  local missing_env_json
  missing_env_json="$(required_env_json)"
  local dotnet_note
  local jdbc_note
  dotnet_note="$dotnet_status"
  jdbc_note="$jdbc_status"

  local freeze_reasons_json="[]"
  if (( ${#release_freeze_reasons[@]} > 0 )); then
    freeze_reasons_json='['
    for freeze_reason in "${release_freeze_reasons[@]}"; do
      if [[ "${freeze_reasons_json}" != "[" ]]; then
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
  "dotnet": {
    "status": "$dotnet_note"
  },
  "jdbc": {
    "status": "$jdbc_note"
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

exec > >(tee "$LOG_FILE") 2>&1

echo "JDBC-203 cross-runtime pooling contract run"
echo "timestamp: $TIMESTAMP"
echo "root: $ROOT_DIR"
echo "strict_gate: $strict_gate"

echo
attempt_dotnet_env_autoload || true
refresh_required_env
if [[ -z "${SCRATCHBIRD_DOTNET_URL:-}" ]]; then
  echo "[warn] SCRATCHBIRD_DOTNET_URL not set; .NET phase cannot run"
  dotnet_status="env_missing"
elif [[ -z "${SCRATCHBIRD_DOTNET_CANCEL_SQL:-}" ]]; then
  echo "[warn] SCRATCHBIRD_DOTNET_CANCEL_SQL not set; .NET phase cannot run required cancel-reuse scenarios"
  dotnet_status="env_missing"
else
  can_run_dotnet="true"
  dotnet_url="${SCRATCHBIRD_DOTNET_URL}"
  if [[ "${dotnet_url}" == sb://* ]]; then
    dotnet_url="scratchbird://${dotnet_url#sb://}"
    echo "[warn] normalized SCRATCHBIRD_DOTNET_URL from sb:// to scratchbird://"
  fi
  if [[ "${dotnet_url}" == *"://"* && "${dotnet_url%%://*}" != "scratchbird" ]]; then
    echo "[warn] SCRATCHBIRD_DOTNET_URL has unsupported scheme '${dotnet_url%%://*}'"
    echo "       .NET URL formats supported: scratchbird://host:port/db?query or key=value semicolon/string pairs."
    dotnet_status="failed"
    release_freeze="true"
    release_freeze_reasons+=("dotnet_contract_failed")
    exit_code=1
    can_run_dotnet="false"
  else
    export SCRATCHBIRD_DOTNET_URL="$dotnet_url"
    echo "[info] using .NET DSN: $SCRATCHBIRD_DOTNET_URL"
  fi
  if [[ "${can_run_dotnet:-false}" == "true" ]]; then
    echo "[step] .NET pooling phase (isolated per case)"
    set +e
    run_dotnet_contract_phase
    dotnet_rc=$?
    set -e
    if [[ "$dotnet_rc" -eq 0 ]]; then
      dotnet_status="passed"
    else
      dotnet_status="failed"
      release_freeze="true"
      release_freeze_reasons+=("dotnet_contract_failed")
      exit_code=1
      echo "[fail] .NET pooling phase failed with exit code $dotnet_rc"
    fi
  fi
fi

echo
if [[ -n "${SCRATCHBIRD_JDBC_URL:-}" && "${SCRATCHBIRD_JDBC_URL}" != jdbc:scratchbird:* ]]; then
  echo "[warn] SCRATCHBIRD_JDBC_URL must start with jdbc:scratchbird:. Got '${SCRATCHBIRD_JDBC_URL}'"
  jdbc_status="failed"
  release_freeze="true"
  release_freeze_reasons+=("jdbc_contract_failed")
  exit_code=1
else
  if [[ -z "${SCRATCHBIRD_JDBC_URL:-}" ]]; then
    echo "[info] SCRATCHBIRD_JDBC_URL not set; JDBC phase will use local runtime bootstrap from test harness"
  else
    echo "[info] using JDBC URL: ${SCRATCHBIRD_JDBC_URL}"
  fi
  if [[ -z "${SCRATCHBIRD_JDBC_CANCEL_SQL:-}" ]]; then
    echo "[info] SCRATCHBIRD_JDBC_CANCEL_SQL not set; JDBC runtime harness will select a default cancel probe"
  fi
  echo "[step] JDBC pooling phase"
  cd "$ROOT_DIR/tracks/alpha/drivers/jdbc"
  set +e
  ./gradlew test --tests "com.scratchbird.jdbc.JDBC203PoolingAndRecoveryContractTest" \
    -Dorg.gradle.warning.mode=none
  jdbc_rc=$?
  set -e
  if [[ "$jdbc_rc" -eq 0 ]]; then
    jdbc_status="passed"
  else
    jdbc_status="failed"
    release_freeze="true"
    release_freeze_reasons+=("jdbc_contract_failed")
    exit_code=1
    echo "[fail] JDBC pooling phase failed with exit code $jdbc_rc"
  fi
fi

refresh_required_env
if [[ "${dotnet_status}" == "passed" && "${jdbc_status}" == "passed" ]]; then
  overall_status="pass"
  reason="both_runtimes_executed"
  echo "[pass] both runtime envs present; cross-runtime contract artifacts recorded in $OUTDIR"
elif [[ "${dotnet_status}" == "failed" || "${jdbc_status}" == "failed" ]]; then
  overall_status="failed"
  reason="runtime_contract_failure"
  echo "[fail] one or both runtime contract suites failed; release-freeze is active"
elif [[ "${#required_env[@]}" -eq 0 ]]; then
  overall_status="partial"
  reason="runtime_tests_executed_with_expected_skips"
  echo "[warn] one or both runtimes skipped due missing environment while strict_gate is false"
else
  overall_status="blocked"
  if [[ "${strict_gate}" == "true" || "${strict_gate}" == "1" ]]; then
    reason="strict_gate_missing_env"
  else
    reason="missing_env_for_full_cross_runtime_contract"
  fi
  echo "[warn] blocked by missing env for both-runtimes gate; capture blocker reason in notes.md"
fi

if [[ "$overall_status" == "failed" ]]; then
  release_freeze="true"
  release_freeze_reasons+=("runtime_contract_failure")
fi
if [[ "${strict_gate}" == "true" || "${strict_gate}" == "1" ]]; then
  if [[ "$overall_status" == "blocked" || "$overall_status" == "failed" ]]; then
    release_freeze="true"
    if [[ "$overall_status" == "blocked" ]]; then
      release_freeze_reasons+=("strict_gate_missing_env")
    fi
  fi
fi

finalize
if [[ "$overall_status" == "blocked" ]]; then
  exit_code=0
  if [[ "${strict_gate}" == "true" || "${strict_gate}" == "1" ]]; then
    exit_code=1
  fi
fi
if [[ "$overall_status" == "pass" ]]; then
  exit_code=0
fi
exit "$exit_code"
