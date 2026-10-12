<#
.SYNOPSIS
  Downloads the VPN core and rule sets from their official releases.
  Nothing downloaded here is committed (see .gitignore).

.DESCRIPTION
  - sing-box.exe  (github.com/SagerNet/sing-box releases)  -> third_party/core/windows/
  - wintun.dll    (www.wintun.net)                         -> third_party/core/windows/
  - *.srs rule sets (SagerNet/sing-geoip, sing-geosite)    -> assets/rules/
  Pinned SHA-256 hashes live in scripts/core_versions.json; a mismatch aborts.
  Run with -UpdatePins after bumping versions to record new hashes.

.EXAMPLE
  ./scripts/fetch_core.ps1
  ./scripts/fetch_core.ps1 -Only rules
#>
param(
  [ValidateSet('all', 'windows', 'rules')] [string] $Only = 'all',
  [switch] $UpdatePins,
  [switch] $Force
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$root = Split-Path -Parent $PSScriptRoot
$pinsPath = Join-Path $PSScriptRoot 'core_versions.json'
$pins = Get-Content $pinsPath -Raw | ConvertFrom-Json
$tmp = Join-Path ([IO.Path]::GetTempPath()) "aurora-core-$([guid]::NewGuid())"
New-Item -ItemType Directory -Force $tmp | Out-Null

function Get-File([string] $url, [string] $out) {
  Write-Host "  GET $url"
  & curl.exe -L --fail --retry 3 -s -o $out $url
  if ($LASTEXITCODE -ne 0) { throw "download failed: $url" }
}

function Confirm-Hash([string] $file, [string] $key) {
  $actual = (Get-FileHash $file -Algorithm SHA256).Hash.ToLower()
  $expected = $pins.sha256.$key
  if ($UpdatePins -or -not $expected) {
    $pins.sha256 | Add-Member -NotePropertyName $key -NotePropertyValue $actual -Force
    Write-Host "  pinned $key = $actual"
  } elseif ($expected -ne $actual) {
    throw "SHA-256 mismatch for $key`n  expected $expected`n  actual   $actual"
  }
}

try {
  if ($Only -in 'all', 'windows') {
    $dest = Join-Path $root 'third_party/core/windows'
    New-Item -ItemType Directory -Force $dest | Out-Null
    $v = $pins.singbox
    if ($Force -or -not (Test-Path "$dest/sing-box.exe")) {
      Write-Host "sing-box $v (windows-amd64)"
      $zip = Join-Path $tmp 'sing-box.zip'
      Get-File "https://github.com/SagerNet/sing-box/releases/download/v$v/sing-box-$v-windows-amd64.zip" $zip
      Confirm-Hash $zip "sing-box-$v-windows-amd64.zip"
      Expand-Archive $zip -DestinationPath $tmp -Force
      Copy-Item (Get-ChildItem $tmp -Recurse -Filter 'sing-box.exe' | Select-Object -First 1).FullName "$dest/sing-box.exe" -Force
      Copy-Item (Get-ChildItem $tmp -Recurse -Filter 'LICENSE' | Select-Object -First 1).FullName "$dest/LICENSE.sing-box" -Force
    }
    $w = $pins.wintun
    if ($Force -or -not (Test-Path "$dest/wintun.dll")) {
      Write-Host "wintun $w"
      $zip = Join-Path $tmp 'wintun.zip'
      Get-File "https://www.wintun.net/builds/wintun-$w.zip" $zip
      Confirm-Hash $zip "wintun-$w.zip"
      Expand-Archive $zip -DestinationPath "$tmp/wintun" -Force
      Copy-Item "$tmp/wintun/wintun/bin/amd64/wintun.dll" "$dest/wintun.dll" -Force
      Copy-Item "$tmp/wintun/wintun/LICENSE.txt" "$dest/LICENSE.wintun.txt" -Force
    }
  }

  if ($Only -in 'all', 'rules') {
    $dest = Join-Path $root 'assets/rules'
    New-Item -ItemType Directory -Force $dest | Out-Null
    $sets = @{
      'geoip-ru'                 = "https://raw.githubusercontent.com/SagerNet/sing-geoip/$($pins.geoip_commit)/geoip-ru.srs"
      'geosite-category-ru'      = "https://raw.githubusercontent.com/SagerNet/sing-geosite/$($pins.geosite_commit)/geosite-category-ru.srs"
      'geosite-category-ads-all' = "https://raw.githubusercontent.com/SagerNet/sing-geosite/$($pins.geosite_commit)/geosite-category-ads-all.srs"
    }
    foreach ($name in $sets.Keys) {
      $out = "$dest/$name.srs"
      if ($Force -or -not (Test-Path $out)) {
        Write-Host "rule set $name"
        Get-File $sets[$name] $out
        Confirm-Hash $out "$name.srs"
      }
    }
  }

  if ($UpdatePins) {
    $pins | ConvertTo-Json -Depth 5 | Set-Content $pinsPath -Encoding utf8
    Write-Host "Updated $pinsPath"
  }
  Write-Host 'Done.'
} finally {
  Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}
