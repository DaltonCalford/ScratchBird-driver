#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUTDIR="${ROOT_DIR}/artifacts/enterprise-readiness/JDBC-203"
mkdir -p "$OUTDIR"
LOG_FILE="$OUTDIR/contract_run_${TIMESTAMP}.log"
SUMMARY_FILE="$OUTDIR/contract_gate_summary_${TIMESTAMP}.json"

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

exec > >(tee "$LOG_FILE") 2>&1

echo "JDBC-203 cross-runtime pooling contract run"
echo "timestamp: $TIMESTAMP"
echo "root: $ROOT_DIR"
echo "strict_gate: $strict_gate"

if [[ "${#required_env[@]}" -gt 0 && ("$strict_gate" == "true" || "$strict_gate" == "1") ]]; then
  echo "[blocker] strict_gate enabled; required environment variables are missing: ${required_env[*]}"
  echo "[blocker] exiting before execution"
  cat > "$SUMMARY_FILE" <<JSON
{
  "timestamp": "$TIMESTAMP",
  "strictGate": "$strict_gate",
  "dotnet": {
    "status": "$dotnet_status",
    "note": "not_executed"
  },
  "jdbc": {
    "status": "$jdbc_status",
    "note": "not_executed"
  },
  "overallStatus": "blocked",
  "reason": "strict_gate_enabled_and_required_env_missing"
}
JSON
  exit 1
fi

echo
if [[ -z "${SCRATCHBIRD_DOTNET_URL:-}" ]]; then
  echo "[warn] SCRATCHBIRD_DOTNET_URL not set; .NET phase cannot run"
  dotnet_status="env_missing"
else
  echo "[step] .NET pooling phase"
  cd "$ROOT_DIR"
  dotnet test tracks/alpha/drivers/dotnet/tests/ScratchBird.Data.Tests/ScratchBird.Data.Tests.csproj \
    --filter "FullyQualifiedName~JDBC203PoolingAndRecoveryContractTest|FullyQualifiedName~JDBC203PoolingAndRecoveryContractTests|FullyQualifiedName~Pooling" \
    -l "trx;LogFileName=artifacts/enterprise-readiness/JDBC-203/dotnet_pooling_contract.trx"
  dotnet_status="passed"
fi

echo
if [[ -z "${SCRATCHBIRD_JDBC_URL:-}" ]]; then
  echo "[warn] SCRATCHBIRD_JDBC_URL not set; JDBC phase cannot run"
  jdbc_status="env_missing"
else
  echo "[step] JDBC pooling phase"
  cd "$ROOT_DIR/tracks/alpha/drivers/jdbc"
  ./gradlew test --tests "com.scratchbird.jdbc.JDBC203*" \
    -Dorg.gradle.warning.mode=none
  jdbc_status="passed"
fi

overall_status="partial"
if [[ "${dotnet_status}" == "passed" && "${jdbc_status}" == "passed" ]]; then
  overall_status="pass"
  reason="both_runtimes_executed"
  echo "[pass] both runtime envs present; cross-runtime contract artifacts recorded in $OUTDIR"
elif [[ "${#required_env[@]}" -eq 0 ]]; then
  overall_status="partial"
  reason="runtime_tests_executed_with_expected_skips"
  echo "[warn] one or both runtimes skipped due missing environment while strict_gate is false"
else
  overall_status="blocked"
  reason="missing_env_for_full_cross_runtime_contract"
  echo "[warn] blocked by missing env for both-runtimes gate; capture blocker reason in notes.md"
fi

cat > "$SUMMARY_FILE" <<JSON
{
  "timestamp": "$TIMESTAMP",
  "strictGate": "$strict_gate",
  "dotnet": {
    "status": "$dotnet_status"
  },
  "jdbc": {
    "status": "$jdbc_status"
  },
  "overallStatus": "$overall_status",
  "reason": "$reason",
  "missingEnv": [$(printf '"%s",' "${required_env[@]}" | sed 's/,$//' )]
}
JSON
