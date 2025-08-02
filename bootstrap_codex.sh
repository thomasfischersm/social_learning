#!/usr/bin/env bash
set -euo pipefail
# 1) make every Gradle wrapper runnable so Codex’s scanner won’t choke
find . -type f -name "gradlew" -exec chmod +x {} \;
# 2) guarantee the file Gradle asserts on
[[ -f android/local.properties ]] || echo "# filled by bootstrap" > android/local.properties
# 3) hand off to the real (heavy) setup
exec bash tool/codex_setup.sh
