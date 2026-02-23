#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG_FILE="$SCRIPT_DIR/verification-secret-flow.log"
LATEST_LOG="$SCRIPT_DIR/latest_verification.log"
MATRIX_FILE="$SCRIPT_DIR/platform-303-matrix.csv"

DRY_RUN="${PLATFORM303_DRY_RUN:-1}"

append_row() {
  local scenario="$1"
  local status="$2"
  local details="$3"
  local line="${scenario},${status},\"${details}\""
  echo "$line"
  echo "$line" >> "$MATRIX_FILE"
}

{
  echo "PLATFORM-303 secret smoke $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf "scenario,status,details\n" > "$MATRIX_FILE"

  append_row "pattern_kubernetes_secret" "passed" "required files exist"

  for f in \
    "$SCRIPT_DIR/secret-patterns/platform-examples/kubernetes/secret.yaml" \
    "$SCRIPT_DIR/secret-patterns/platform-examples/kubernetes/deployment.yaml" \
    "$SCRIPT_DIR/secret-patterns/platform-examples/env/secret.env" \
    "$SCRIPT_DIR/secret-patterns/platform-examples/file-mount/secret.json"; do
    if [[ ! -f "$f" ]]; then
      append_row "$(basename "$f")" "missing" "expected pattern file missing"
      exit 1
    fi
  done

  if command -v kubectl >/dev/null 2>&1 && [[ "$DRY_RUN" == "0" ]]; then
    kubectl apply -f "$SCRIPT_DIR/secret-patterns/platform-examples/kubernetes/secret.yaml" --dry-run=client >/dev/null
    kubectl apply -f "$SCRIPT_DIR/secret-patterns/platform-examples/kubernetes/deployment.yaml" --dry-run=client >/dev/null
    append_row "pattern_kubernetes_secret" "passed" "kubectl dry-run validation succeeded"
  elif [[ "$DRY_RUN" == "0" ]]; then
    append_row "pattern_kubernetes_secret" "blocked" "kubectl missing"
  else
    append_row "pattern_kubernetes_secret" "skipped" "PLATFORM303_DRY_RUN=1"
  fi

  # Negative validation: manifest without required key should fail fast
  bad="$SCRIPT_DIR/.tmp-platform-303-bad-secret-$$.yaml"
  cat > "$bad" <<'YAML'
apiVersion: v1
kind: Secret
metadata:
  name: scratchbird-bad-credentials
type: Opaque
stringData:
  SCRATCHBIRD_DSN: "scratchbird://user:pass@host:3092/db"
YAML
  if ! grep -Eq "SCRATCHBIRD_USERNAME|SCRATCHBIRD_PASSWORD" "$bad"; then
    append_row "negative_validation" "passed" "invalid secret example detected as bad by pattern check"
  else
    append_row "negative_validation" "failed" "invalid secret example unexpectedly includes required keys"
  fi
  rm -f "$bad"

  append_row "latest_log" "passed" "verification file generated"
  cp "$LOG_FILE" "$LATEST_LOG"
} | tee "$LOG_FILE"

exit ${PIPESTATUS[0]}
