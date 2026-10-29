# Installs the built launcher on the TV and opens it. The TV's default home screen is left unchanged.
param([string]$TvHost = $env:AUT_TV_HOST)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\common.ps1"

if (-not (Test-Path $Apk)) { throw 'No APK yet. Run scripts\build.ps1 first.' }
$TvHost = Resolve-TvHost $TvHost
$adb = Connect-Tv $TvHost
& $adb -s "${TvHost}:5555" install -r $Apk
if ($LASTEXITCODE -ne 0) { throw 'Install failed.' }
& $adb -s "${TvHost}:5555" shell am start -n $HomeActivity
Write-Host "AmazingUltraTV is installed and open on the TV."
