#!/usr/bin/env bash
set -euo pipefail
# 1) make every Gradle wrapper runnable so Codex’s scanner won’t choke
find . -type f -name "gradlew" -exec chmod +x {} \;
# 2) guarantee the file Gradle asserts on
flutter_sdk="${FLUTTER_HOME:-}"
if [[ -z "${flutter_sdk}" && -n "$(command -v flutter 2>/dev/null)" ]]; then
  flutter_sdk="$(dirname "$(dirname "$(command -v flutter)")")"
fi
if [[ -n "${flutter_sdk}" ]]; then
  if [[ -f android/local.properties ]]; then
    grep -q '^flutter\.sdk=' android/local.properties || echo "flutter.sdk=${flutter_sdk}" >> android/local.properties
  else
    echo "flutter.sdk=${flutter_sdk}" > android/local.properties
  fi
else
  [[ -f android/local.properties ]] || touch android/local.properties
fi
# 3) hand off to the real (heavy) setup
exec bash tool/codex_setup.sh
