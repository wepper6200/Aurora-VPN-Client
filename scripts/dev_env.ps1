# Dot-source this file to put the portable toolchain (D:\dev by default) on PATH
# for the current PowerShell session:
#   . .\scripts\dev_env.ps1
# Override the root with $env:AURORA_TOOLS before sourcing.

$tools = if ($env:AURORA_TOOLS) { $env:AURORA_TOOLS } else { 'D:\dev' }

$env:JAVA_HOME = "$tools\jdk-17"
$env:ANDROID_HOME = "$tools\android-sdk"
$env:ANDROID_SDK_ROOT = "$tools\android-sdk"
$env:PUB_CACHE = "$tools\pub-cache"
$env:GRADLE_USER_HOME = "$tools\gradle"
$env:GOPATH = "$tools\gopath"
$env:GOMODCACHE = "$tools\gopath\pkg\mod"
$env:GOCACHE = "$tools\gocache"

$prepend = @(
  "$tools\flutter\bin",
  "$tools\git\cmd",
  "$tools\jdk-17\bin",
  "$tools\go\bin",
  "$tools\gopath\bin",
  "$tools\android-sdk\cmdline-tools\latest\bin",
  "$tools\android-sdk\platform-tools",
  "$tools\inno-setup",
  "$tools\gh\bin"
)
$rest = ($env:Path -split ';') | Where-Object { $_ -and ($prepend -notcontains $_) }
$env:Path = (($prepend + $rest) -join ';')
