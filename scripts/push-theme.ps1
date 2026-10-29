# Applies a theme folder (config.json, plus wallpaper.jpg or wallpapers/) to AmazingUltraTV on the TV and
# restarts Home. -Reset removes the applied theme so the launcher's built-in look returns.
param(
    [Parameter(Position = 0)][string]$Theme,
    [switch]$Reset,
    [string]$TvHost = $env:AUT_TV_HOST
)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\common.ps1"

$MaxConfigBytes = 64KB   # the launcher ignores a larger config.json
$Uri = "content://$Package.theme"
$Dir = "/sdcard/Android/data/$Package/files"
$Tmp = '/data/local/tmp/aut-theme'

# Everything is checked before the TV is contacted, so a bad theme never half-applies.
if ($Theme -and $Reset) { throw 'Pass a theme folder or -Reset, not both. Nothing was sent to the TV.' }
if (-not $Theme -and -not $Reset) { throw 'Usage: push-theme.ps1 <theme folder>   or   push-theme.ps1 -Reset' }
$images = @()
if ($Theme) {
    $config = Join-Path $Theme 'config.json'
    if (-not (Test-Path $config -PathType Leaf)) { throw "$Theme is not a theme: it has no config.json. Nothing was sent to the TV." }
    $size = (Get-Item $config).Length
    if ($size -gt $MaxConfigBytes) { throw "$config is $size bytes; the launcher accepts at most $MaxConfigBytes. Nothing was sent to the TV." }
    try { $json = Get-Content $config -Raw | ConvertFrom-Json } catch { throw "$config is not valid JSON. Nothing was sent to the TV." }
    if ($json -isnot [System.Management.Automation.PSCustomObject]) { throw "$config must be a JSON object of theme keys. Nothing was sent to the TV." }
    $wallpapers = Join-Path $Theme 'wallpapers'
    if (Test-Path $wallpapers -PathType Container) {
        $images = @(Get-ChildItem $wallpapers -File | Where-Object { $_.Extension -match '^\.(jpg|jpeg|png|webp)$' })
        $bad = @($images | Where-Object { $_.Name -notmatch '^[A-Za-z0-9_.-]+$' -or $_.Name.StartsWith('.') })
        if ($bad.Count) { throw "The launcher can't use the wallpaper name $($bad[0].Name). Nothing was sent to the TV." }
    }
}

$TvHost = Resolve-TvHost $TvHost
$adb = Connect-Tv $TvHost

# Moves a file already staged on the TV into the theme through the launcher's ThemeProvider, falling back
# to the app's files folder on firmware whose content command can't write. No double quotes: Windows
# PowerShell would mangle them on the way to adb.
function Set-ThemeFile([string]$Staged, [string]$Name) {
    Invoke-Tv ("rm -f $Dir/$Name 2>/dev/null; { o=`$(content write --uri $Uri/$Name < $Staged 2>&1) && " +
        "case `$o in *Unsupported*) false ;; esac; } || cp $Staged $Dir/$Name 2>/dev/null; rm -f $Staged") | Out-Null
}
function Send-ThemeFile([string]$Local, [string]$Name) {
    $staged = "$Tmp-$($Name -replace '/', '-')"
    & $adb -s "${TvHost}:5555" push $Local $staged | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Could not copy $Local to the TV." }
    Set-ThemeFile $staged $Name
}
function Remove-ThemeFile([string]$Name) {
    Invoke-Tv "rm -f $Dir/$Name 2>/dev/null; content delete --uri $Uri/$Name 2>/dev/null" | Out-Null
}
function Clear-Wallpapers {
    Invoke-Tv "mkdir -p $Dir/wallpapers 2>/dev/null; rm -f $Dir/wallpapers/* 2>/dev/null; content delete --uri $Uri/wallpapers 2>/dev/null" | Out-Null
}

Invoke-Tv "mkdir -p $Dir 2>/dev/null" | Out-Null
if ($Reset) {
    Remove-ThemeFile 'config.json'
    Remove-ThemeFile 'wallpaper.jpg'
    Clear-Wallpapers
} else {
    Send-ThemeFile $config 'config.json'
    $wall = Join-Path $Theme 'wallpaper.jpg'
    if (Test-Path $wall) { Send-ThemeFile $wall 'wallpaper.jpg' } else { Remove-ThemeFile 'wallpaper.jpg' }
    Clear-Wallpapers
    foreach ($image in $images) { Send-ThemeFile $image.FullName "wallpapers/$($image.Name)" }
    $captions = Join-Path $wallpapers 'captions.txt'
    if (Test-Path $captions -PathType Leaf) { Send-ThemeFile $captions 'wallpapers/captions.txt' }
}

# A new revision tells the launcher to reload, then Home restarts so the theme shows at once.
Invoke-Tv "printf %s $([guid]::NewGuid().ToString('N')) > $Tmp-theme_revision" | Out-Null
Set-ThemeFile "$Tmp-theme_revision" 'theme_revision'
Invoke-Tv "am force-stop $Package" | Out-Null
if ((Get-HomeOwner) -eq $HomeActivity) { Invoke-Tv 'am start -a android.intent.action.MAIN -c android.intent.category.HOME' | Out-Null }
else { Invoke-Tv "am start -n $HomeActivity" | Out-Null }

if ($Reset) { Write-Host 'The theme is removed; AmazingUltraTV is back to its built-in look.' }
else { Write-Host "Theme $(Split-Path $Theme -Leaf) is on the TV. Undo with: scripts\push-theme.ps1 -Reset" }
