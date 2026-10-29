# Saves the TV's current state (apps, home screen, settings) to backups\<date>, so every change can be undone.
param([string]$TvHost = $env:AUT_TV_HOST)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\common.ps1"

$TvHost = Resolve-TvHost $TvHost
$adb = Connect-Tv $TvHost
$dir = Join-Path $Root ("backups\" + (Get-Date -Format 'yyyy-MM-dd_HHmmss'))
New-Item -ItemType Directory -Force $dir | Out-Null

$snapshots = [ordered]@{
    'packages-all.txt'      = 'pm list packages -u'
    'packages-disabled.txt' = 'pm list packages -d'
    'packages-user.txt'     = 'pm list packages -3'
    'home-launcher.txt'     = 'cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME'
    'settings-global.txt'   = 'settings list global'
    'settings-secure.txt'   = 'settings list secure'
    'settings-system.txt'   = 'settings list system'
    'props.txt'             = 'getprop'
}
foreach ($name in $snapshots.Keys) {
    & $adb -s "${TvHost}:5555" shell $snapshots[$name] | Set-Content -Encoding utf8 (Join-Path $dir $name)
}
Write-Host "Backup saved to $dir"
