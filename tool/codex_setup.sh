#!/usr/bin/env bash
# tool/codex_setup.sh
# Idempotent setup for Flutter & Firebase CLI
# Works on Linux/macOS; adapt paths for Windows/PowerShell if needed.

set -euo pipefail

# ──────────────────────────────────────────────────────────────────────────────
# Version pins – bump these when you upgrade the toolchain
# ──────────────────────────────────────────────────────────────────────────────
FLUTTER_VERSION="3.32.8"
FIREBASE_CLI_VERSION="14.11.2"

# ──────────────────────────────────────────────────────────────────────────────
# Directories
# ──────────────────────────────────────────────────────────────────────────────
CACHE_DIR="${HOME}/.cache/codex_deps"
FLUTTER_DIR="${CACHE_DIR}/flutter_${FLUTTER_VERSION}"
PATH_TO_ADD="${FLUTTER_DIR}/bin:${HOME}/.pub-cache/bin"

# Ensure java-server’s Gradle wrapper is runnable
chmod +x java-server/gradlew

# Create android/local.properties if missing
if [[ ! -f android/local.properties ]]; then
  cat > android/local.properties <<EOF
flutter.sdk=${FLUTTER_DIR}
EOF
fi


# Fast-exit if everything is already in place
if [[ -x "${FLUTTER_DIR}/bin/flutter" ]] && \
   [[ "$(firebase --version 2>/dev/null || true)" == "${FIREBASE_CLI_VERSION}" ]]; then
  export PATH="${PATH_TO_ADD}:${PATH}"
  echo "✔ Flutter ${FLUTTER_VERSION} & Firebase CLI ${FIREBASE_CLI_VERSION} already set up"
  exit 0
fi

mkdir -p "${CACHE_DIR}"

# ──────────────────────────────────────────────────────────────────────────────
# 1️⃣  Install / cache Flutter SDK
# ──────────────────────────────────────────────────────────────────────────────
if [[ ! -x "${FLUTTER_DIR}/bin/flutter" ]]; then
  echo "⏳ Downloading Flutter ${FLUTTER_VERSION} …"
  curl -sL \
    "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    | tar -xJ -C "${CACHE_DIR}"
  mv "${CACHE_DIR}/flutter" "${FLUTTER_DIR}"
fi
export PATH="${PATH_TO_ADD}:${PATH}"

# Pre-warm Flutter (avoids first-run hiccups)
flutter --version
flutter precache --universal

# ──────────────────────────────────────────────────────────────────────────────
# 2️⃣  Install / update Firebase CLI
# ──────────────────────────────────────────────────────────────────────────────
if [[ "$(firebase --version 2>/dev/null || true)" != "${FIREBASE_CLI_VERSION}" ]]; then
  echo "⏳ Installing Firebase CLI ${FIREBASE_CLI_VERSION} …"
  npm install -g "firebase-tools@${FIREBASE_CLI_VERSION}"
fi
firebase --version

# ──────────────────────────────────────────────────────────────────────────────
# 3️⃣  Get Dart/Flutter dependencies
# ──────────────────────────────────────────────────────────────────────────────
flutter pub get

# Optionally install flutterfire CLI if you use it
if ! command -v flutterfire &> /dev/null; then
  dart pub global activate flutterfire_cli
fi

echo "✅ Toolchain ready — Flutter ${FLUTTER_VERSION}, Firebase CLI ${FIREBASE_CLI_VERSION}"
