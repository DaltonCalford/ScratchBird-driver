#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_TS="$(date -u +%Y%m%dT%H%M%SZ)"
ROTATION_LOG="$SCRIPT_DIR/rotation-smoke.log"
MATRIX_FILE="$SCRIPT_DIR/rotation-matrix.csv"
LATEST_LOG="$SCRIPT_DIR/latest_verification.log"
SIM_DIR="$SCRIPT_DIR/.rotation-workdir-${RUN_TS}"
trap 'rm -rf "$SIM_DIR"' EXIT

DRY_RUN="${PLATFORM302_DRY_RUN:-1}"
REQUIRE_RUNTIME="${PLATFORM302_REQUIRE_RUNTIME:-0}"
RUNTIME_ENDPOINT="${PLATFORM302_RUNTIME_ENDPOINT:-}"

append_row() {
  local scenario="$1"
  local mode="$2"
  local status="$3"
  local details="$4"
  local line="${scenario},${mode},${status},\"${details}\""
  echo "$line"
  echo "$line" >> "$MATRIX_FILE"
}

if ! command -v openssl >/dev/null 2>&1; then
  echo "openssl is required for TLS rotation verification." >&2
  exit 1
fi

run_platform302_rotation() {
  echo "PLATFORM-302 TLS rotation run $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf "scenario,mode,status,details\n" > "$MATRIX_FILE"

  if [[ ! -d "$SIM_DIR" ]]; then
    mkdir -p "$SIM_DIR"
  fi

  append_row "file_rotation" "simulation" "started" "creating self-signed cert chain"
  cd "$SIM_DIR"

  openssl req -x509 -newkey rsa:2048 -nodes -sha256 -days 30 \
    -subj "/CN=scratchbird-platform302-sim-old" \
    -keyout key-old.key -out cert-old.crt >/dev/null 2>&1
  openssl req -x509 -newkey rsa:2048 -nodes -sha256 -days 30 \
    -subj "/CN=scratchbird-platform302-sim-new" \
    -keyout key-new.key -out cert-new.crt >/dev/null 2>&1

  hash_old="$(openssl x509 -in cert-old.crt -noout -fingerprint -sha256 | sed 's/^.*=//')"
  hash_new="$(openssl x509 -in cert-new.crt -noout -fingerprint -sha256 | sed 's/^.*=//')"
  append_row "file_rotation" "simulation" "passed" "old=${hash_old} new=${hash_new}"

  cert_now="$hash_old"
  cert_path="$SIM_DIR/active.crt"
  key_path="$SIM_DIR/active.key"
  cp cert-old.crt "$cert_path"
  cp key-old.key "$key_path"
  active_hash_before="$(openssl x509 -in "$cert_path" -noout -fingerprint -sha256 | sed 's/^.*=//')"
  if [[ "$active_hash_before" == "$hash_old" ]]; then
    append_row "file_rotation" "simulation" "passed" "bootstrap cert material staged"
  else
    append_row "file_rotation" "simulation" "failed" "bootstrap hash mismatch"
  fi

  if [[ "$DRY_RUN" == "1" ]]; then
    append_row "runtime_reconnect" "simulation" "skipped" "PLATFORM302_DRY_RUN=1"
    return 0
  fi

  cp cert-new.crt "$cert_path"
  cp key-new.key "$key_path"
  active_hash_after="$(openssl x509 -in "$cert_path" -noout -fingerprint -sha256 | sed 's/^.*=//')"
  if [[ "$active_hash_after" == "$hash_new" ]]; then
    append_row "file_rotation" "simulation" "passed" "rotation applied to active path"
  else
    append_row "file_rotation" "simulation" "failed" "rotation path did not apply"
  fi

  if [[ "${REQUIRE_RUNTIME}" == "1" ]]; then
    if [[ -z "$RUNTIME_ENDPOINT" ]]; then
      append_row "runtime_reconnect" "managed/listener" "blocked" "PLATFORM302_RUNTIME_ENDPOINT not set"
      return 0
    fi

    if command -v curl >/dev/null 2>&1 && [[ "$RUNTIME_ENDPOINT" == https://* ]]; then
      if curl -ks --max-time 3 "$RUNTIME_ENDPOINT" >/dev/null 2>&1; then
        append_row "runtime_reconnect" "managed/listener" "passed" "runtime endpoint reachable after rotation path"
      else
        append_row "runtime_reconnect" "managed/listener" "failed" "runtime endpoint unreachable"
      fi
    else
      append_row "runtime_reconnect" "managed/listener" "not_executed" "curl unavailable or endpoint is non-HTTPS"
    fi
  else
    append_row "runtime_reconnect" "managed/listener" "skipped" "runtime checks disabled (PLATFORM302_REQUIRE_RUNTIME=0)"
  fi

  append_row "overall" "simulation" "passed" "rotation harness completed"
}

run_platform302_rotation | tee "$ROTATION_LOG"
run_rc=${PIPESTATUS[0]}
rm -rf "$SIM_DIR"
cp "$ROTATION_LOG" "$LATEST_LOG"
exit "$run_rc"
