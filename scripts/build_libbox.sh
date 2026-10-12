#!/usr/bin/env bash
# Builds android/app/libs/libbox.aar: sing-box's libbox plus our Xray-core
# bridge (native/corebridge) in one gomobile library. Mirrors build_libbox.ps1.
# Requires Go, JDK 17, ANDROID_HOME with the pinned NDK.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PINS="$ROOT/scripts/core_versions.json"
pin() { python3 -c "import json,sys;print(json.load(open(sys.argv[1], encoding='utf-8-sig'))[sys.argv[2]])" "$PINS" "$1"; }
NDK_VERSION="$(pin ndk)"
SINGBOX="$(pin singbox)"
XRAY_MODULE="$(pin xray_module)"
TARGETS="${LIBBOX_TARGETS:-android/arm64,android/arm,android/amd64}"

: "${ANDROID_HOME:?ANDROID_HOME is not set}"
export ANDROID_NDK_HOME="$ANDROID_HOME/ndk/$NDK_VERSION"
# Same Go release as upstream sing-box builds (badtls/linkname depend on it).
export GOTOOLCHAIN="go$(pin go)"
[ -d "$ANDROID_NDK_HOME" ] || { echo "NDK $NDK_VERSION not found"; exit 1; }

cd "$ROOT/native/corebridge"
[ "$(go list -m -f '{{.Version}}' github.com/sagernet/sing-box)" = "v$SINGBOX" ] || { echo "sing-box version mismatch"; exit 1; }
[ "$(go list -m -f '{{.Version}}' github.com/xtls/xray-core)" = "$XRAY_MODULE" ] || { echo "xray-core version mismatch"; exit 1; }
GOMOBILE="$(go list -m -f '{{.Version}}' github.com/sagernet/gomobile)"
go install "github.com/sagernet/gomobile/cmd/gomobile@$GOMOBILE"
go install "github.com/sagernet/gomobile/cmd/gobind@$GOMOBILE"
export PATH="$(go env GOPATH)/bin:$PATH"

TAGS="with_gvisor,with_quic,with_wireguard,with_utls,with_clash_api,badlinkname,tfogo_checklinkname0"
LDFLAGS="-X github.com/sagernet/sing-box/constant.Version=$SINGBOX -X runtime.godebugDefault=multipathtcp=0,tlssha1=1 -checklinkname=0 -s -w -buildid="

rm -rf build
gomobile bind -v -o libbox.aar -target "$TARGETS" -androidapi 24 \
  -javapkg=io.nekohasekai -libname=box -trimpath -buildvcs=false \
  -ldflags "$LDFLAGS" -tags "$TAGS" \
  github.com/sagernet/sing-box/experimental/libbox ./xraybridge

mkdir -p "$ROOT/android/app/libs"
mv libbox.aar "$ROOT/android/app/libs/libbox.aar"
rm -f libbox-sources.jar
echo "libbox.aar -> android/app/libs ($(du -h "$ROOT/android/app/libs/libbox.aar" | cut -f1))"
