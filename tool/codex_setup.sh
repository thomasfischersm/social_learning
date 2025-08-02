#!/usr/bin/env bash
# tool/codex_setup.sh – full tool-chain bootstrap
set -euo pipefail

# ───── Versions (latest stable as of Aug 2025) ───────────
FLUTTER_VERSION="3.32.8"   # stable release May 20 2025 :contentReference[oaicite:0]{index=0}
FIREBASE_CLI_VERSION="14.11.2"   # latest CLI on npm, 30 Jul 2025 :contentReference[oaicite:1]{index=1}

# ───── Directories ───────────────────────────────────────
CACHE_DIR="${HOME}/.cache/codex"
FLUTTER_DIR="${CACHE_DIR}/flutter_${FLUTTER_VERSION}"
export PATH="${FLUTTER_DIR}/bin:${HOME}/.pub-cache/bin:${PATH}"

# ensure every wrapper is executable (if someone cloned without the mode bit)
find . -type f -name "gradlew" -exec chmod +x {} \;

# write a complete android/local.properties (Gradle already saw a stub)
ANDROID_SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-/opt/android-sdk}}"
cat > android/local.properties <<EOF
sdk.dir=${ANDROID_SDK}
flutter.sdk=${FLUTTER_DIR}
EOF

# ───── Install / cache Flutter SDK ───────────────────────
if [[ ! -x "${FLUTTER_DIR}/bin/flutter" ]]; then
  mkdir -p "${CACHE_DIR}"
  echo "⇒ Downloading Flutter ${FLUTTER_VERSION}…"
  curl -sL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    | tar -xJ -C "${CACHE_DIR}"
  mv "${CACHE_DIR}/flutter" "${FLUTTER_DIR}"
fi

flutter --version
flutter precache --universal

# ───── Install / update Firebase CLI ─────────────────────
if [[ "$(firebase --version 2>/dev/null || true)" != "${FIREBASE_CLI_VERSION}" ]]; then
  npm install -g "firebase-tools@${FIREBASE_CLI_VERSION}"
fi
firebase --version

# ───── Get Dart/Flutter dependencies ─────────────────────
flutter pub get

# Optional: FlutterFire CLI
command -v flutterfire >/dev/null || dart pub global activate flutterfire_cli

echo "✅  Tool-chain ready – Flutter ${FLUTTER_VERSION}, Firebase CLI ${FIREBASE_CLI_VERSION}"
