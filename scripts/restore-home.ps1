# Puts the Google TV home screen back: re-enables it and the setup wizard, and makes it the default again.
# AmazingUltraTV stays installed; remove it with: adb uninstall com.amazingultratv.home
param([string]$TvHost = $env:AUT_TV_HOST)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\common.ps1"

$TvHost = Resolve-TvHost $TvHost
$adb = Connect-Tv $TvHost
Invoke-Tv "pm enable --user 0 $SetupWizard"
Invoke-Tv "pm enable --user 0 $StockLauncher"
Invoke-Tv "cmd package set-home-activity --user 0 $StockLauncher/.home.HomeActivity"
Invoke-Tv 'input keyevent KEYCODE_HOME'
Write-Host "The Google TV home screen is back ($(Get-HomeOwner))."
