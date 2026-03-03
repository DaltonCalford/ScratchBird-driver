#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  build-p2-update-site.sh [output-dir]

Description:
  Builds the ScratchBird DBeaver extension and assembles a p2 update-site zip
  that can be installed into a stock DBeaver download with:
  Help -> Install New Software -> Add -> Archive...
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INTEGRATION_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
OUTPUT_DIR="${1:-${INTEGRATION_DIR}/dist}"

choose_maven() {
  if [[ -n "${MAVEN_CMD:-}" ]]; then
    echo "${MAVEN_CMD}"
    return 0
  fi

  if [[ -x "${HOME}/CliWork/dbeaver-common/mvnw" ]]; then
    echo "${HOME}/CliWork/dbeaver-common/mvnw"
    return 0
  fi

  if command -v mvn >/dev/null 2>&1; then
    echo "mvn"
    return 0
  fi

  return 1
}

MAVEN="$(choose_maven || true)"
if [[ -z "${MAVEN}" ]]; then
  echo "No Maven launcher found. Install 'mvn' or set MAVEN_CMD." >&2
  exit 1
fi

${MAVEN} -f "${INTEGRATION_DIR}/pom.xml" clean verify -DskipTests

REPOSITORY_DIR="${INTEGRATION_DIR}/repository/target/repository"
if [[ ! -f "${REPOSITORY_DIR}/content.jar" && ! -f "${REPOSITORY_DIR}/content.xml" ]]; then
  echo "p2 repository output was not generated: ${REPOSITORY_DIR}" >&2
  exit 1
fi

mkdir -p "${OUTPUT_DIR}"
TIMESTAMP="$(date +%Y%m%dT%H%M%S)"
ZIP_PATH="$(cd "${OUTPUT_DIR}" && pwd)/scratchbird-dbeaver-update-site-${TIMESTAMP}.zip"

(
  cd "${REPOSITORY_DIR}"
  zip -qr "${ZIP_PATH}" .
)

cat <<EOF2
p2 update site built successfully.

Repository folder:
  ${REPOSITORY_DIR}

Archive:
  ${ZIP_PATH}

Install in DBeaver:
  Help -> Install New Software -> Add -> Archive...
EOF2
