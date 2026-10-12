#!/usr/bin/env bash
# Builds libbox.aar (sing-box for Android) from official sources with gomobile
# into android/app/libs/. Requires Go, JDK 17, ANDROID_HOME with the NDK.
# Mirrors scripts/build_libbox.ps1; versions come from scripts/core_versions.json.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PINS="$ROOT/scripts/core_versions.json"
VERSION="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1], encoding='utf-8-sig'))['singbox'])" "$PINS")"
NDK_VERSION="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1], encoding='utf-8-sig'))['ndk'])" "$PINS")"
SRC="${SING_BOX_SRC:-$ROOT/build/sing-box-src}"
TARGETS="${LIBBOX_TARGETS:-android/arm64,android/arm,android/amd64}"

: "${ANDROID_HOME:?ANDROID_HOME is not set}"
export ANDROID_NDK_HOME="$ANDROID_HOME/ndk/$NDK_VERSION"
[ -d "$ANDROID_NDK_HOME" ] || { echo "NDK $NDK_VERSION not found"; exit 1; }

if [ ! -d "$SRC/.git" ]; then
  git clone --quiet --depth 1 --branch "v$VERSION" https://github.com/SagerNet/sing-box.git "$SRC"
fi

GOMOBILE="$(awk '/github.com\/sagernet\/gomobile /{print $2}' "$SRC/go.mod")"
cd "$SRC"
go install "github.com/sagernet/gomobile/cmd/gomobile@$GOMOBILE"
go install "github.com/sagernet/gomobile/cmd/gobind@$GOMOBILE"
export PATH="$(go env GOPATH)/bin:$PATH"

TAGS="with_gvisor,with_quic,with_wireguard,with_utls,with_clash_api,badlinkname,tfogo_checklinkname0"
LDFLAGS="-X github.com/sagernet/sing-box/constant.Version=$VERSION -X runtime.godebugDefault=multipathtcp=0,tlssha1=1 -checklinkname=0 -s -w -buildid="

gomobile bind -v -o libbox.aar -target "$TARGETS" -androidapi 24 \
  -javapkg=io.nekohasekai -libname=box -trimpath -buildvcs=false \
  -ldflags "$LDFLAGS" -tags "$TAGS" ./experimental/libbox

mkdir -p "$ROOT/android/app/libs"
cp libbox.aar "$ROOT/android/app/libs/libbox.aar"
echo "libbox.aar -> android/app/libs ($(du -h libbox.aar | cut -f1))"
