<#
.SYNOPSIS
  Release build for Windows: core binaries, flutter build, portable zip and
  (with -Installer) the Inno Setup installer. Output goes to dist\.

.EXAMPLE
  ./scripts/build_windows.ps1 -Installer
#>
param(
  # Also compile installer\aurora_vpn.iss (needs Inno Setup 6: ISCC.exe).
  [switch]$Installer,
  # Skip fetch_core.ps1 when third_party/core/windows is already in place.
  [switch]$SkipFetch
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

function Invoke-Native([string]$exe, [string[]]$arguments) {
  & $exe @arguments
  if ($LASTEXITCODE -ne 0) { throw "$exe exited with $LASTEXITCODE" }
}

# Version from pubspec.yaml ("0.1.0+1" -> name 0.1.0, build 1).
$line = Select-String -Path pubspec.yaml -Pattern '^version:\s*(\S+)' | Select-Object -First 1
$full = $line.Matches[0].Groups[1].Value
$name, $build = $full.Split('+')
if (-not $build) { $build = '1' }
Write-Host "Aurora VPN $name ($build)"

if (-not $SkipFetch -or -not (Test-Path third_party/core/windows/sing-box.exe)) {
  & ./scripts/fetch_core.ps1
}

Invoke-Native flutter @('build', 'windows', '--release', "--build-name=$name", "--build-number=$build")

$release = 'build/windows/x64/runner/Release'
foreach ($f in @('aurora_vpn.exe', 'core/sing-box.exe', 'core/xray.exe', 'core/wintun.dll')) {
  if (-not (Test-Path "$release/$f")) { throw "missing $release/$f" }
}

New-Item -ItemType Directory -Force dist | Out-Null
$zip = "dist/AuroraVPN-$name-windows-x64-portable.zip"
if (Test-Path $zip) { Remove-Item $zip }
Compress-Archive -Path "$release/*" -DestinationPath $zip
Write-Host "portable: $zip"

if ($Installer) {
  $iscc = (Get-Command ISCC.exe -ErrorAction SilentlyContinue).Source
  if (-not $iscc) {
    $iscc = @(
      "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
      "$env:ProgramFiles\Inno Setup 6\ISCC.exe",
      "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe"
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1
  }
  if (-not $iscc) { throw 'Inno Setup 6 (ISCC.exe) not found' }
  Invoke-Native $iscc @('/Q', "/DAppVersion=$name", 'installer/aurora_vpn.iss')
  Write-Host "installer: dist/AuroraVPN-$name-windows-x64-setup.exe"
}
