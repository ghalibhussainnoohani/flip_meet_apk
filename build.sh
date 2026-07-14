#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# FlipMeet Flutter – one-shot build script
# Run from the flutter_flipmeet/ directory:  bash build.sh
# ─────────────────────────────────────────────────────────────────────────────
set -e
cd "$(dirname "$0")"

# ── 1. Check Flutter is installed ────────────────────────────────────────────
if ! command -v flutter &>/dev/null; then
  echo "❌  Flutter SDK not found. Install from https://flutter.dev/docs/get-started/install"
  exit 1
fi
echo "✅  Flutter: $(flutter --version | head -1)"

# ── 2. Scaffold a temporary project to pull in default icons & resources ──────
TMP=$(mktemp -d)
echo "🔧  Scaffolding temp project at $TMP …"
flutter create --org com.flipmeet --project-name flipmeet \
  --platforms android --template app "$TMP" >/dev/null 2>&1

# Copy default mipmap icons (all densities)
cp -r "$TMP/android/app/src/main/res/mipmap-"* \
      android/app/src/main/res/
# Copy Flutter's generated local.properties (contains flutter.sdk path)
[ -f "$TMP/android/local.properties" ] && \
  cp "$TMP/android/local.properties" android/local.properties

rm -rf "$TMP"
echo "✅  Default icons copied"

# ── 3. Install pub packages ───────────────────────────────────────────────────
echo "📦  Running flutter pub get …"
flutter pub get

# ── 4. Build release APK ─────────────────────────────────────────────────────
echo "🏗   Building release APK …"
flutter build apk --release

OUT="build/app/outputs/flutter-apk/app-release.apk"
if [ -f "$OUT" ]; then
  SIZE=$(du -sh "$OUT" | awk '{print $1}')
  echo ""
  echo "──────────────────────────────────────────────────────"
  echo "✅  APK ready  →  $OUT  ($SIZE)"
  echo "──────────────────────────────────────────────────────"
else
  echo "❌  Build failed – APK not found."
  exit 1
fi
