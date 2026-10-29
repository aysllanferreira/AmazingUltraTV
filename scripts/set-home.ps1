# Makes AmazingUltraTV the TV's home screen. Backs up first, turns the Google TV home off with
# pm disable-user (nothing is uninstalled), and rolls back if the Home button doesn't land here.
# Undo any time with scripts\restore-home.ps1.
param(
    [string]$TvHost = $env:AUT_TV_HOST,
    # Also turn off Google TV's setup wizard, for when it grabs Home after the stock launcher is off.
    [switch]$AlsoDisableSetupWizard
)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\common.ps1"

$TvHost = Resolve-TvHost $TvHost
$adb = Connect-Tv $TvHost
if (-not (Invoke-Tv "pm path $Package")) { throw 'AmazingUltraTV is not installed. Run scripts\install.ps1 first.' }
& "$PSScriptRoot\backup-tv.ps1" -TvHost $TvHost

Invoke-Tv "pm disable-user --user 0 $StockLauncher"
if ($AlsoDisableSetupWizard) { Invoke-Tv "pm disable-user --user 0 $SetupWizard" }
Invoke-Tv "cmd package set-home-activity --user 0 $HomeActivity"
Invoke-Tv 'input keyevent KEYCODE_HOME'
Start-Sleep -Seconds 3

$owner = Get-HomeOwner
$resumed = "$(Invoke-Tv 'dumpsys activity activities | grep -m 1 mResumedActivity')"
if ($owner -eq $HomeActivity -and $resumed -match [regex]::Escape($Package)) {
    Write-Host 'AmazingUltraTV is now the home screen. Undo with scripts\restore-home.ps1.'
    exit 0
}

Write-Warning "The Home button went to '$owner' instead. Rolling back."
& "$PSScriptRoot\restore-home.ps1" -TvHost $TvHost
if ($owner -match 'setupwraith') { Write-Warning "Google TV's setup wizard claimed Home. Run again with -AlsoDisableSetupWizard." }
exit 1
