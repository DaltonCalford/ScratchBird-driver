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
if [[ -z "${SCRATCHBIRD_DOTNET_URL:-}" ]]; then
  required_env+=("SCRATCHBIRD_DOTNET_URL")
fi
if [[ -z "${SCRATCHBIRD_DOTNET_CANCEL_SQL:-}" ]]; then
  required_env+=("SCRATCHBIRD_DOTNET_CANCEL_SQL")
fi
if [[ -z "${SCRATCHBIRD_JDBC_URL:-}" ]]; then
  required_env+=("SCRATCHBIRD_JDBC_URL")
fi
if [[ -z "${SCRATCHBIRD_JDBC_CANCEL_SQL:-}" ]]; then
  required_env+=("SCRATCHBIRD_JDBC_CANCEL_SQL")
fi

strict_gate="${JDBC203_STRICT_GATE:-${GITHUB_ACTIONS:-false}}"
strict_gate="${strict_gate,,}"

dotnet_status="not_run"
jdbc_status="not_run"
release_freeze="false"
release_freeze_reasons=()
overall_status="partial"
reason="runtime_tests_executed_with_expected_skips"
exit_code=0

missing_env_json="[]"
if (( ${#required_env[@]} > 0 )); then
  missing_env_json='['
  for env_name in "${required_env[@]}"; do
    if [[ "${missing_env_json}" != "[" ]]; then
      missing_env_json+=","
    fi
    missing_env_json+="\"${env_name}\""
  done
  missing_env_json+="]"
fi

write_summary() {
  local summary_file="$1"
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
if [[ -z "${SCRATCHBIRD_DOTNET_URL:-}" ]]; then
  echo "[warn] SCRATCHBIRD_DOTNET_URL not set; .NET phase cannot run"
  dotnet_status="env_missing"
else
  echo "[step] .NET pooling phase"
  cd "$ROOT_DIR"
  set +e
  dotnet test tracks/alpha/drivers/dotnet/tests/ScratchBird.Data.Tests/ScratchBird.Data.Tests.csproj \
    --filter "FullyQualifiedName~JDBC203PoolingAndRecoveryContractTest|FullyQualifiedName~JDBC203PoolingAndRecoveryContractTests|FullyQualifiedName~Pooling" \
    -l "trx;LogFileName=artifacts/enterprise-readiness/JDBC-203/dotnet_pooling_contract.trx"
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

echo
if [[ -z "${SCRATCHBIRD_JDBC_URL:-}" ]]; then
  echo "[warn] SCRATCHBIRD_JDBC_URL not set; JDBC phase cannot run"
  jdbc_status="env_missing"
else
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
