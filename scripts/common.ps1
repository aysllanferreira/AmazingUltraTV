# Shared setup for the AmazingUltraTV scripts: finds Java, the Android SDK and adb, and connects to the TV.
$Root = Split-Path -Parent $PSScriptRoot
$Package = 'com.amazingultratv.home'
$HomeActivity = "$Package/com.gathin.tvhome.MainActivity"
$Apk = Join-Path $Root 'launcher\app\build\outputs\apk\release\app-release.apk'
$StockLauncher = 'com.google.android.apps.tv.launcherx'
# Google TV's setup wizard also claims Home (RecoveryActivity) and can take over once the stock launcher is off.
$SetupWizard = 'com.google.android.tungsten.setupwraith'

function Find-Adb {
    $cmd = Get-Command adb -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $candidates = @("$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe") +
        @(Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\Google.PlatformTools*\platform-tools\adb.exe" -ErrorAction SilentlyContinue | ForEach-Object FullName)
    foreach ($c in $candidates) { if ($c -and (Test-Path $c)) { return $c } }
    throw 'adb not found. Install it with: winget install Google.PlatformTools'
}

function Use-BuildTools {
    if (-not $env:JAVA_HOME) {
        $jdk = Get-ChildItem 'C:\Program Files\Microsoft' -Directory -Filter 'jdk-17*' -ErrorAction SilentlyContinue |
            Sort-Object Name -Descending | Select-Object -First 1
        if (-not $jdk) { throw 'JDK 17 not found. Install it with: winget install Microsoft.OpenJDK.17' }
        $env:JAVA_HOME = $jdk.FullName
    }
    if (-not $env:ANDROID_HOME) { $env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk" }
    $env:Path = "$env:JAVA_HOME\bin;$env:Path"
}

# The TV's address: the script's -TvHost, which defaults to the AUT_TV_HOST environment variable.
# No address is built in, so nobody's home network ends up in the repo.
function Resolve-TvHost([string]$TvHost) {
    if ($TvHost) { return $TvHost }
    throw ("No TV address. Pass -TvHost <tv-ip>, or set it once for your user with:`n" +
        "  [Environment]::SetEnvironmentVariable('AUT_TV_HOST', '<tv-ip>', 'User')")
}

# Returns the adb path once the TV is connected and has authorized this PC; changes nothing on the TV.
function Connect-Tv([string]$TvHost) {
    # Windows PowerShell turns adb's stderr into errors; read it as text instead.
    $ErrorActionPreference = 'Continue'
    $adb = Find-Adb
    $out = "$(& $adb connect "${TvHost}:5555" 2>&1)"
    $state = "$(& $adb -s "${TvHost}:5555" get-state 2>&1)".Trim()
    if ($state -eq 'device') { return $adb }
    if ($out -match 'authenticate' -or $state -match 'unauthorized') {
        throw "The TV at $TvHost hasn't authorized this computer yet. Accept 'Allow USB debugging?' on the TV, then run this again."
    }
    throw "Could not reach the TV at ${TvHost}. Check that it is on, on the same network, and has network debugging enabled. ($out)"
}

# Runs a shell command on the TV. Uses the calling script's $adb and $TvHost.
function Invoke-Tv([string]$Command) {
    & $adb -s "${TvHost}:5555" shell $Command
}

# The activity the Home button opens, e.g. com.google.android.apps.tv.launcherx/.home.HomeActivity.
function Get-HomeOwner {
    "$(Invoke-Tv 'cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME' | Select-Object -Last 1)".Trim()
}
