<#
.SYNOPSIS
  Builds libbox.aar (sing-box for Android) from the official sources with
  gomobile and puts it into android/app/libs/. The AAR is not committed.

.DESCRIPTION
  Requires Go, JDK 17 and an Android SDK with NDK (ANDROID_HOME set).
  The sing-box version comes from scripts/core_versions.json. Only the
  features this client uses are compiled in (no Tailscale/OpenVPN/naive),
  which keeps the AAR several times smaller than the upstream build.

.EXAMPLE
  . ./scripts/dev_env.ps1; ./scripts/build_libbox.ps1
#>
param(
  [string] $SourceDir = $(if ($env:AURORA_TOOLS) { "$env:AURORA_TOOLS/src/sing-box" } else { 'D:/dev/src/sing-box' }),
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
$pins = Get-Content (Join-Path $PSScriptRoot 'core_versions.json') -Raw | ConvertFrom-Json
$version = $pins.singbox
$ndkVersion = $pins.ndk

if (-not $env:ANDROID_HOME) { throw 'ANDROID_HOME is not set' }
$ndk = Join-Path $env:ANDROID_HOME "ndk/$ndkVersion"
if (-not (Test-Path $ndk)) { throw "NDK $ndkVersion not found at $ndk (sdkmanager `"ndk;$ndkVersion`")" }
$env:ANDROID_NDK_HOME = $ndk

# Sources at the pinned tag.
if (-not (Test-Path "$SourceDir/.git")) {
  Invoke-Native 'git clone' { git clone --quiet --depth 1 --branch "v$version" https://github.com/SagerNet/sing-box.git $SourceDir }
} else {
  $current = & { $ErrorActionPreference = 'Continue'; git -C $SourceDir describe --tags --exact-match 2>$null }
  if ($current -ne "v$version") {
    Invoke-Native 'git fetch' { git -C $SourceDir fetch --quiet --depth 1 origin "refs/tags/v$version:refs/tags/v$version" }
    Invoke-Native 'git checkout' { git -C $SourceDir checkout --quiet "v$version" }
  }
}

# gomobile fork pinned by sing-box's go.mod.
$gomobile = (Select-String -Path "$SourceDir/go.mod" -Pattern 'github.com/sagernet/gomobile (v\S+)').Matches[0].Groups[1].Value
Push-Location $SourceDir
try {
  Invoke-Native 'go install gobind' { go install "github.com/sagernet/gomobile/cmd/gobind@$gomobile" }
  $gobin = Join-Path (go env GOPATH) 'bin'
  $env:PATH = "$gobin;$env:PATH"

  # gomobile panics on Windows' hidden per-drive variables ("=C:=C:\…"): its
  # environ() skips them in the inherited list but not in the child's list.
  # Build it from a patched copy that treats both lists the same way.
  Invoke-Native 'go mod download gomobile' { go mod download "github.com/sagernet/gomobile@$gomobile" }
  $modDir = (& go list -m -f '{{.Dir}}' "github.com/sagernet/gomobile@$gomobile")
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
  $ldflags = "-X github.com/sagernet/sing-box/constant.Version=$version -X runtime.godebugDefault=multipathtcp=0,tlssha1=1 -checklinkname=0"
  if (-not $Debug) { $ldflags += ' -s -w -buildid=' }

  Write-Host "gomobile bind sing-box $version ($Targets)"
  # Every flag is quoted: Windows PowerShell splits unquoted '-x=a.b' at the dot.
  Invoke-Native 'gomobile bind' { gomobile bind '-v' '-o' 'libbox.aar' '-target' $Targets '-androidapi' '24' `
    '-javapkg=io.nekohasekai' '-libname=box' '-trimpath' '-buildvcs=false' `
    '-ldflags' $ldflags '-tags' $tags './experimental/libbox' }

  $dest = Join-Path $root 'android/app/libs'
  New-Item -ItemType Directory -Force $dest | Out-Null
  Copy-Item libbox.aar (Join-Path $dest 'libbox.aar') -Force
  Write-Host "libbox.aar -> $dest ($([math]::Round((Get-Item libbox.aar).Length / 1MB, 1)) MB)"
} finally {
  Pop-Location
}
