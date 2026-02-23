# PLATFORM-301 Verification Notes (2026-02-23)

## Status
Code-complete for smoke artifacts; runtime verification is environment dependent.

## Scope
Deliver a deployable Helm chart + sidecar route and a smoke script that validates
chart renderability and optional cluster behavior.

## Evidence Implemented
- `artifacts/enterprise-readiness/PLATFORM-301/charts/scratchbird-sidecar/Chart.yaml`
- `artifacts/enterprise-readiness/PLATFORM-301/charts/scratchbird-sidecar/values.yaml`
- `artifacts/enterprise-readiness/PLATFORM-301/charts/scratchbird-sidecar/templates/_helpers.tpl`
- `artifacts/enterprise-readiness/PLATFORM-301/charts/scratchbird-sidecar/templates/deployment.yaml`
- `artifacts/enterprise-readiness/PLATFORM-301/charts/scratchbird-sidecar/templates/service.yaml`
- `artifacts/enterprise-readiness/PLATFORM-301/charts/scratchbird-sidecar/templates/sidecar-configmap.yaml`
- `artifacts/enterprise-readiness/PLATFORM-301/charts/scratchbird-sidecar/templates/NOTES.txt`
- `artifacts/enterprise-readiness/PLATFORM-301/run-platform-301-k8s-smoke.sh`
- `artifacts/enterprise-readiness/PLATFORM-301/platform-301-matrix.csv` (generated during run)

## Latest Verification
- `artifacts/enterprise-readiness/PLATFORM-301/latest_verification.log`
- `artifacts/enterprise-readiness/PLATFORM-301/platform-301-matrix.csv`

## Run Command
```bash
PLATFORM_301_DRY_RUN=1 bash artifacts/enterprise-readiness/PLATFORM-301/run-platform-301-k8s-smoke.sh
```

To run cluster checks (if a local Kubernetes cluster is available):
```bash
PLATFORM_301_DRY_RUN=0 PLATFORM_301_REQUIRE_CLUSTER=1 bash artifacts/enterprise-readiness/PLATFORM-301/run-platform-301-k8s-smoke.sh
```

## Acceptance
- [x] Sidecar-oriented Helm chart is available and renderable.
- [x] Sidecar/proxy service and scratchbird service are defined.
- [x] Smoke script records structured scenario results in `platform-301-matrix.csv`.
- [ ] Full cluster smoke must be executed in an environment with `helm` + `kubectl`.
*** End Patch
