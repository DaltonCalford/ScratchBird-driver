#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
CHART_DIR="$SCRIPT_DIR/charts/scratchbird-sidecar"
MATRIX_FILE="$SCRIPT_DIR/platform-301-matrix.csv"
RUN_LOG="$SCRIPT_DIR/platform-301-run-$(date -u +%Y%m%dT%H%M%SZ).log"
LATEST_LOG="$SCRIPT_DIR/latest_verification.log"

DRY_RUN="${PLATFORM_301_DRY_RUN:-1}"
REQUIRE_CLUSTER="${PLATFORM_301_REQUIRE_CLUSTER:-0}"
NAMESPACE="${PLATFORM_301_NAMESPACE:-scratchbird-enterprise-readiness}"
RELEASE_NAME="${PLATFORM_301_RELEASE:-scratchbird-sidecar-plt}"
TIMEOUT="${PLATFORM_301_TIMEOUT_SECONDS:-120}"
KEEP_RELEASE="${PLATFORM_301_KEEP_RELEASE:-0}"

append_row() {
  local scenario="$1"
  local status="$2"
  local details="$3"
  local line="${scenario},${status},\"${details}\""
  echo "$line"
  echo "$line" >> "$MATRIX_FILE"
}

log() {
  echo "$@"
}

if [[ ! -d "$CHART_DIR" ]]; then
  echo "Chart directory missing: $CHART_DIR" >&2
  exit 1
fi

{
  echo "PLATFORM-301 smoke run $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "Repository root: $REPO_ROOT"
  echo "Chart: $CHART_DIR"
  echo "Dry run: $DRY_RUN"
  echo "Require cluster: $REQUIRE_CLUSTER"

  mkdir -p "$SCRIPT_DIR"
  printf "scenario,status,details\n" > "$MATRIX_FILE"
  append_row "render" "started" "helm template"

  if ! command -v helm >/dev/null 2>&1; then
    append_row "render" "blocked" "helm binary missing"
    if [[ "${DRY_RUN}" == "1" ]]; then
      append_row "cluster_smoke" "skipped" "helm unavailable"
      echo "No helm binary; cannot run render-only smoke"
      cp "$RUN_LOG" "$LATEST_LOG"
      exit 0
    fi
    exit 1
  fi

  TEMPLATE_LOG="$SCRIPT_DIR/platform-301-template.log"
  if ! helm template "$RELEASE_NAME" "$CHART_DIR" --namespace "$NAMESPACE" > "$TEMPLATE_LOG" 2>&1; then
    append_row "render" "failed" "helm template failed (see platform-301-template.log)"
    cat "$TEMPLATE_LOG" >&2
    cp "$RUN_LOG" "$LATEST_LOG"
    exit 1
  fi
  append_row "render" "passed" "helm template produced manifests"

  if [[ "${DRY_RUN}" == "1" ]]; then
    append_row "cluster_smoke" "skipped" "PLATFORM_301_DRY_RUN=1 (default)"
    echo "Dry-run mode; skipping cluster bootstrap."
    cp "$RUN_LOG" "$LATEST_LOG"
    exit 0
  fi

  if ! command -v kubectl >/dev/null 2>&1; then
    append_row "cluster_smoke" "blocked" "kubectl missing"
    echo "kubectl missing; cannot run cluster smoke."
    [[ "${REQUIRE_CLUSTER}" == "1" ]] && exit 1
    cp "$RUN_LOG" "$LATEST_LOG"
    exit 0
  fi

  if ! kubectl get ns "$NAMESPACE" >/dev/null 2>&1; then
    kubectl create namespace "$NAMESPACE" >/dev/null
    append_row "namespace_setup" "passed" "created namespace $NAMESPACE"
  else
    append_row "namespace_setup" "passed" "namespace existed"
  fi

  set +e
  helm upgrade --install "$RELEASE_NAME" "$CHART_DIR" \
    --namespace "$NAMESPACE" \
    --wait --timeout "${TIMEOUT}s" > "$SCRIPT_DIR/platform-301-install.log" 2>&1
  install_rc=$?
  set -e

  if [[ "$install_rc" -ne 0 ]]; then
    append_row "cluster_smoke" "failed" "helm upgrade/install failed"
    echo "helm install output:"
    cat "$SCRIPT_DIR/platform-301-install.log"
    [[ "${REQUIRE_CLUSTER}" == "1" ]] && exit 1 || true
    cp "$RUN_LOG" "$LATEST_LOG"
    exit 0
  fi

  append_row "cluster_smoke" "passed" "helm upgrade/install completed"

  if kubectl -n "$NAMESPACE" rollout status deployment/"$RELEASE_NAME" >/dev/null 2>&1; then
    append_row "deployment_ready" "passed" "deployment rollout completed"
  else
    append_row "deployment_ready" "failed" "rollout timeout or unavailable"
    [[ "${REQUIRE_CLUSTER}" == "1" ]] && exit 1 || true
  fi

  append_row "sidecar_connectivity" "not_run" "manual socket validation requires server-specific smoke endpoint"

  if [[ "${KEEP_RELEASE}" != "1" ]]; then
    helm uninstall "$RELEASE_NAME" --namespace "$NAMESPACE" >/dev/null 2>&1 || true
    append_row "cleanup" "passed" "release removed"
  else
    append_row "cleanup" "skipped" "PLATFORM_301_KEEP_RELEASE=1"
  fi

  cp "$RUN_LOG" "$LATEST_LOG"
} | tee "$RUN_LOG"

exit ${PIPESTATUS[0]}
