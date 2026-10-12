#!/usr/bin/env bash
# Release build for Android: libbox (if missing), rule sets, then per-ABI and
# universal APKs. Signing: android/key.properties (see README); without it
# the release APKs are signed with the debug key.
#
#   bash scripts/build_android.sh
set -euo pipefail
cd "$(dirname "$0")/.."

version=$(sed -n 's/^version:[[:space:]]*//p' pubspec.yaml | head -n1)
name=${version%%+*}
build=${version#*+}
[ "$build" = "$version" ] && build=1
echo "Aurora VPN $name ($build)"

if [ ! -f android/app/libs/libbox.aar ]; then
  bash scripts/build_libbox.sh
fi
if command -v pwsh >/dev/null; then
  pwsh ./scripts/fetch_core.ps1 -Only rules
elif [ ! -f assets/rules/geoip-ru.srs ]; then
  echo "assets/rules missing: run scripts/fetch_core.ps1 -Only rules (PowerShell)" >&2
  exit 1
fi
[ -f android/key.properties ] || echo "warning: android/key.properties not found, using the debug key" >&2

flutter build apk --release --split-per-abi --build-name="$name" --build-number="$build"
flutter build apk --release --build-name="$name" --build-number="$build"

mkdir -p dist
out=build/app/outputs/flutter-apk
cp "$out/app-arm64-v8a-release.apk" "dist/AuroraVPN-$name-android-arm64-v8a.apk"
cp "$out/app-armeabi-v7a-release.apk" "dist/AuroraVPN-$name-android-armeabi-v7a.apk"
cp "$out/app-x86_64-release.apk" "dist/AuroraVPN-$name-android-x86_64.apk"
cp "$out/app-release.apk" "dist/AuroraVPN-$name-android-universal.apk"
ls -lh dist/*.apk
