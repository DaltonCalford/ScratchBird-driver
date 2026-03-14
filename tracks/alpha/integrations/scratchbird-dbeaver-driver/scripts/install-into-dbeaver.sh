#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  install-into-dbeaver.sh /absolute/or/relative/path/to/dbeaver

Description:
  Copies ScratchBird DBeaver plugin sources into a DBeaver source checkout and
  patches required module/feature files so the plugin is built and bundled.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INTEGRATION_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
DBEAVER_DIR="$(cd "$1" && pwd)"

require_file() {
  local file="$1"
  if [[ ! -f "${file}" ]]; then
    echo "Missing expected file: ${file}" >&2
    exit 1
  fi
}

insert_after_regex_once() {
  local file="$1"
  local presence_regex="$2"
  local anchor_regex="$3"
  local new_line="$4"

  if grep -Eq "${presence_regex}" "${file}"; then
    return 0
  fi

  local tmp
  tmp="$(mktemp)"

  if ! awk -v re="${anchor_regex}" -v ins="${new_line}" '
    {
      print $0
      if (!inserted && $0 ~ re) {
        print ins
        inserted = 1
      }
    }
    END {
      if (!inserted) {
        exit 2
      }
    }
  ' "${file}" > "${tmp}"; then
    rm -f "${tmp}"
    echo "Failed to patch ${file}: anchor regex not found: ${anchor_regex}" >&2
    exit 1
  fi

  mv "${tmp}" "${file}"
}

sync_dir() {
  local src="$1"
  local dst="$2"
  rm -rf "${dst}"
  mkdir -p "$(dirname "${dst}")"
  cp -a "${src}" "${dst}"
}

write_dbeaver_reactor_poms() {
  cat > "${DBEAVER_DIR}/plugins/org.jkiss.dbeaver.ext.scratchbird/pom.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd"
         xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>org.jkiss.dbeaver</groupId>
        <artifactId>plugins</artifactId>
        <version>1.0.0-SNAPSHOT</version>
        <relativePath>../</relativePath>
    </parent>
    <artifactId>org.jkiss.dbeaver.ext.scratchbird</artifactId>
    <version>1.0.1-SNAPSHOT</version>
    <packaging>eclipse-plugin</packaging>
</project>
EOF

  cat > "${DBEAVER_DIR}/test/org.jkiss.dbeaver.ext.scratchbird.test/pom.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd"
         xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>org.jkiss.dbeaver</groupId>
        <artifactId>tests</artifactId>
        <version>1.0.0-SNAPSHOT</version>
        <relativePath>../</relativePath>
    </parent>
    <artifactId>org.jkiss.dbeaver.ext.scratchbird.test</artifactId>
    <version>1.0.0-SNAPSHOT</version>
    <packaging>eclipse-test-plugin</packaging>
</project>
EOF
}

require_file "${DBEAVER_DIR}/plugins/pom.xml"
require_file "${DBEAVER_DIR}/test/pom.xml"
require_file "${DBEAVER_DIR}/features/org.jkiss.dbeaver.db.feature/feature.xml"
require_file "${DBEAVER_DIR}/features/org.jkiss.dbeaver.test.feature/feature.xml"

sync_dir \
  "${INTEGRATION_DIR}/plugins/org.jkiss.dbeaver.ext.scratchbird" \
  "${DBEAVER_DIR}/plugins/org.jkiss.dbeaver.ext.scratchbird"

sync_dir \
  "${INTEGRATION_DIR}/test/org.jkiss.dbeaver.ext.scratchbird.test" \
  "${DBEAVER_DIR}/test/org.jkiss.dbeaver.ext.scratchbird.test"

write_dbeaver_reactor_poms

insert_after_regex_once \
  "${DBEAVER_DIR}/plugins/pom.xml" \
  "<module>org[.]jkiss[.]dbeaver[.]ext[.]scratchbird</module>" \
  "org[.]jkiss[.]dbeaver[.]ext[.]generic</module>" \
  "        <module>org.jkiss.dbeaver.ext.scratchbird</module>"

insert_after_regex_once \
  "${DBEAVER_DIR}/test/pom.xml" \
  "<module>org[.]jkiss[.]dbeaver[.]ext[.]scratchbird[.]test</module>" \
  "org[.]jkiss[.]dbeaver[.]ext[.]generic[.]test</module>" \
  "        <module>org.jkiss.dbeaver.ext.scratchbird.test</module>"

insert_after_regex_once \
  "${DBEAVER_DIR}/features/org.jkiss.dbeaver.db.feature/feature.xml" \
  "plugin id=\"org[.]jkiss[.]dbeaver[.]ext[.]scratchbird\"" \
  "plugin id=\"org[.]jkiss[.]dbeaver[.]ext[.]generic\"" \
  "    <plugin id=\"org.jkiss.dbeaver.ext.scratchbird\" version = \"0.0.0\"/>"

insert_after_regex_once \
  "${DBEAVER_DIR}/features/org.jkiss.dbeaver.test.feature/feature.xml" \
  "plugin id=\"org[.]jkiss[.]dbeaver[.]ext[.]scratchbird[.]test\"" \
  "plugin id=\"org[.]jkiss[.]dbeaver[.]ext[.]generic[.]test\"" \
  "    <plugin id=\"org.jkiss.dbeaver.ext.scratchbird.test\" version=\"0.0.0\"/>"

cat <<EOF
ScratchBird DBeaver integration installed into:
  ${DBEAVER_DIR}

Next steps:
  1) Build JDBC jar:
     cd /home/dcalford/CliWork/ScratchBird-driver/tracks/p3/drivers/jdbc && ./gradlew clean jar
  2) Build plugin/test in DBeaver:
     cd ${DBEAVER_DIR}
     /home/dcalford/CliWork/dbeaver-common/mvnw -f product/aggregate/pom.xml -pl ../../../dbeaver-common/modules/org.jkiss.utils,../../../dbeaver-common/modules/com.dbeaver.jdbc.api,../../plugins/org.jkiss.dbeaver.model,../../plugins/org.jkiss.dbeaver.model.jdbc,../../plugins/org.jkiss.dbeaver.model.lsm,../../plugins/org.jkiss.dbeaver.model.sql,../../plugins/org.jkiss.dbeaver.model.sql.jdbc,../../plugins/org.jkiss.dbeaver.registry,../../plugins/org.jkiss.dbeaver.ext.generic,../../plugins/org.jkiss.dbeaver.ext.scratchbird,../../test/org.jkiss.dbeaver.ext.scratchbird.test -am verify -DskipITs
EOF
