# Builds the launcher APK into launcher\app\build\outputs\apk\release\app-release.apk.
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\common.ps1"
Use-BuildTools

Push-Location (Join-Path $Root 'launcher')
try {
    # local.properties is a Java properties file, so the SDK path needs forward slashes.
    if (-not (Test-Path local.properties)) {
        "sdk.dir=$($env:ANDROID_HOME -replace '\\', '/')" | Set-Content -Encoding ascii local.properties
    }
    & .\gradlew.bat assembleRelease --console=plain
    if ($LASTEXITCODE -ne 0) { throw 'Build failed.' }
} finally {
    Pop-Location
}
Write-Host "Built $Apk"
