<#
.SYNOPSIS
  Builds android/app/libs/libbox.aar: sing-box's libbox plus our Xray-core
  bridge (native/corebridge) in one gomobile library. Not committed.

.DESCRIPTION
  Requires Go, JDK 17 and an Android SDK with the NDK pinned in
  scripts/core_versions.json (ANDROID_HOME set). Module versions come from
  native/corebridge/go.mod (checked against core_versions.json) and are
  verified by go.sum. Only the features this client uses are compiled in.

.EXAMPLE
  . ./scripts/dev_env.ps1; ./scripts/build_libbox.ps1
#>
param(
  [string] $Targets = 'android/arm64,android/arm,android/amd64',
  [switch] $Debug
)

$ErrorActionPreference = 'Stop'

# Windows PowerShell treats any stderr output of native tools (go, git) as an
# error under 'Stop'; run them with 'Continue' and check the exit code instead.
function Invoke-Native([string] $What, [scriptblock] $Command) {
  $saved = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try { & $Command 2>&1 | ForEach-Object { "$_" } } finally { $ErrorActionPreference = $saved }
  if ($LASTEXITCODE -ne 0) { throw "$What failed (exit $LASTEXITCODE)" }
}

$root = Split-Path -Parent $PSScriptRoot
$module = Join-Path $root 'native/corebridge'
$pins = Get-Content (Join-Path $PSScriptRoot 'core_versions.json') -Raw | ConvertFrom-Json

if (-not $env:ANDROID_HOME) { throw 'ANDROID_HOME is not set' }
$ndk = Join-Path $env:ANDROID_HOME "ndk/$($pins.ndk)"
if (-not (Test-Path $ndk)) { throw "NDK $($pins.ndk) not found at $ndk (sdkmanager `"ndk;$($pins.ndk)`")" }
$env:ANDROID_NDK_HOME = $ndk

# sing-box's badtls/linkname code reads crypto/tls internals and is only valid
# for the Go release upstream builds with; a newer Go crashes at the first TLS
# connection. Go downloads and verifies the pinned toolchain itself.
$env:GOTOOLCHAIN = "go$($pins.go)"

Push-Location $module
try {
  $gomobile = (& go list -m -f '{{.Version}}' github.com/sagernet/gomobile)
  $singbox = (& go list -m -f '{{.Version}}' github.com/sagernet/sing-box)
  $xray = (& go list -m -f '{{.Version}}' github.com/xtls/xray-core)
  if ($singbox -ne "v$($pins.singbox)") { throw "go.mod has sing-box $singbox, core_versions.json says $($pins.singbox)" }
  if ($xray -ne $pins.xray_module) { throw "go.mod has xray-core $xray, core_versions.json says $($pins.xray_module)" }

  Invoke-Native 'go install gobind' { go install "github.com/sagernet/gomobile/cmd/gobind@$gomobile" }
  $gobin = Join-Path (go env GOPATH) 'bin'
  $env:PATH = "$gobin;$env:PATH"

  # gomobile panics on Windows' hidden per-drive variables ("=C:=C:\…"): its
  # environ() skips them in the inherited list but not in the child's list.
  # Build it from a patched copy that treats both lists the same way.
  Invoke-Native 'go mod download gomobile' { go mod download "github.com/sagernet/gomobile@$gomobile" }
  $modDir = (& go list -m -f '{{.Dir}}' github.com/sagernet/gomobile)
  $patched = Join-Path ([IO.Path]::GetTempPath()) "aurora-gomobile-$gomobile"
  Remove-Item -Recurse -Force $patched -ErrorAction SilentlyContinue
  Copy-Item -Recurse $modDir $patched
  Get-ChildItem -Recurse -File $patched | ForEach-Object { $_.IsReadOnly = $false }
  $envGo = Join-Path $patched 'cmd/gomobile/env.go'
  $src = [IO.File]::ReadAllText($envGo)
  $needle = "`t`tif len(elem) != 2 || elem[0] == `"`" {`n`t`t`tpanic(fmt.Sprintf(`"malformed env var %q from input`", ev))"
  $fixed = "`t`tif len(elem) != 2 || elem[0] == `"`" {`n`t`t`tnew = append(new, ev)`n`t`t`tcontinue"
  if (-not $src.Contains($needle)) { throw "gomobile ${gomobile}: env.go no longer matches the patch" }
  [IO.File]::WriteAllText($envGo, $src.Replace($needle, $fixed))
  Push-Location $patched
  try { Invoke-Native 'build patched gomobile' { go build -o (Join-Path $gobin 'gomobile.exe') ./cmd/gomobile } }
  finally { Pop-Location }

  $tags = 'with_gvisor,with_quic,with_wireguard,with_utls,with_clash_api,badlinkname,tfogo_checklinkname0'
  $ldflags = "-X github.com/sagernet/sing-box/constant.Version=$($pins.singbox) -X runtime.godebugDefault=multipathtcp=0,tlssha1=1 -checklinkname=0"
  if (-not $Debug) { $ldflags += ' -s -w -buildid=' }

  Remove-Item -Recurse -Force (Join-Path $module 'build') -ErrorAction SilentlyContinue
  Write-Host "gomobile bind: sing-box $singbox + xray-core $xray ($Targets)"
  # Every flag is quoted: Windows PowerShell splits unquoted '-x=a.b' at the dot.
  Invoke-Native 'gomobile bind' { gomobile bind '-v' '-o' 'libbox.aar' '-target' $Targets '-androidapi' '24' `
    '-javapkg=io.nekohasekai' '-libname=box' '-trimpath' '-buildvcs=false' `
    '-ldflags' $ldflags '-tags' $tags `
    'github.com/sagernet/sing-box/experimental/libbox' './xraybridge' }

  $dest = Join-Path $root 'android/app/libs'
  New-Item -ItemType Directory -Force $dest | Out-Null
  Move-Item libbox.aar (Join-Path $dest 'libbox.aar') -Force
  Remove-Item -Force libbox-sources.jar -ErrorAction SilentlyContinue
  Write-Host "libbox.aar -> $dest ($([math]::Round((Get-Item (Join-Path $dest 'libbox.aar')).Length / 1MB, 1)) MB)"
} finally {
  Pop-Location
}
