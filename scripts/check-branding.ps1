# Fails when the upstream product's name shows up in the launcher's user-visible text (string resources
# or the manifest), e.g. after an upstream sync brings in a new translation. Runs on Windows PowerShell
# and on pwsh (CI).
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Main = Join-Path (Join-Path (Join-Path (Join-Path $Root 'launcher') 'app') 'src') 'main'
$UpstreamName = 'CleanYourTV'

$files = @(Get-ChildItem -Path (Join-Path $Main 'res') -Recurse -File -Filter '*.xml') +
    @(Get-Item (Join-Path $Main 'AndroidManifest.xml'))
$hits = @($files | Select-String -SimpleMatch -CaseSensitive -Pattern $UpstreamName)
if ($hits.Count) {
    Write-Host "'$UpstreamName' is the upstream product's name; user-visible text must say AmazingUltraTV:"
    $hits | ForEach-Object { Write-Host ('  {0}:{1}' -f $_.Path.Substring($Root.Length + 1), $_.LineNumber) }
    exit 1
}
Write-Host "Branding check passed: no '$UpstreamName' in the launcher's resources or manifest."
