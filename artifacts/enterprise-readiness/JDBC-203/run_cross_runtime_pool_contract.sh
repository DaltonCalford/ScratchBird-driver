#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUTDIR="${ROOT_DIR}/artifacts/enterprise-readiness/JDBC-203"
mkdir -p "$OUTDIR"
LOG_FILE="$OUTDIR/contract_run_${TIMESTAMP}.log"

exec > >(tee "$LOG_FILE") 2>&1

echo "JDBC-203 cross-runtime pooling contract run"
echo "timestamp: $TIMESTAMP"
echo "root: $ROOT_DIR"

echo
if [[ -z "${SCRATCHBIRD_DOTNET_URL:-}" ]]; then
  echo "[warn] SCRATCHBIRD_DOTNET_URL not set; .NET phase cannot run"
else
  echo "[step] .NET pooling phase"
  cd "$ROOT_DIR"
  dotnet test tracks/alpha/drivers/dotnet/tests/ScratchBird.Data.Tests/ScratchBird.Data.Tests.csproj \
    --filter "FullyQualifiedName~Pool" \
    -l "trx;LogFileName=artifacts/enterprise-readiness/JDBC-203/dotnet_pooling_contract.trx"
fi

echo
if [[ -z "${SCRATCHBIRD_JDBC_URL:-}" ]]; then
  echo "[warn] SCRATCHBIRD_JDBC_URL not set; JDBC phase cannot run"
else
  echo "[step] JDBC pooling phase"
  cd "$ROOT_DIR/tracks/alpha/drivers/jdbc"
  ./gradlew test --tests "com.scratchbird.jdbc.JDBC203*" \
    -Dorg.gradle.warning.mode=none
fi

echo
if [[ -n "${SCRATCHBIRD_DOTNET_URL:-}" && -n "${SCRATCHBIRD_JDBC_URL:-}" ]]; then
  echo "[pass] both driver envs present; run full scenario matrix and record outputs in this directory"
else
  echo "[blocker] both runtimes not available in same pass; capture blocker reason in notes.md"
fi
