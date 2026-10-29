# Pulls CleanYourTV's changes since the recorded baseline into this repo. Pull-only: see UPSTREAM.md.
# Applies upstream's diff for the synced paths with a three-way merge, updates UPSTREAM.md and stages
# everything, leaving the commit (and any conflict resolution) to the maintainer.
param(
    # An upstream branch name (e.g. main) or a full commit sha.
    [Parameter(Mandatory)][string]$To
)
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$UpstreamUrl = 'https://github.com/Gathin23/cleanyourtv.git'
$SyncedPaths = @('launcher', 'themes', '.gitattributes')
$Record = Join-Path $Root 'UPSTREAM.md'

# Runs git and returns its output as text, throwing on failure. Windows PowerShell turns a native
# command's stderr into error records, so Continue is in effect while git runs.
function Invoke-Git {
    $ErrorActionPreference = 'Continue'
    $out = & git -C $Root @args 2>&1 | ForEach-Object { "$_" }
    if ($LASTEXITCODE -ne 0) { throw "git $($args -join ' ') failed:`n$($out -join "`n")" }
    $out
}

function Test-Commit([string]$Sha) {
    $ErrorActionPreference = 'Continue'
    & git -C $Root cat-file -e "$Sha^{commit}" 2>$null
    $LASTEXITCODE -eq 0
}

# Tracked changes anywhere, or stray files inside the synced paths, would mix with upstream's changes.
$changes = @(Invoke-Git status --porcelain --untracked-files=no)
$strays = @(Invoke-Git status --porcelain --untracked-files=all '--' @SyncedPaths | Where-Object { $_.StartsWith('??') })
if ($changes.Count -or $strays.Count) {
    throw 'The working tree has uncommitted changes. Commit or stash them first; nothing was changed.'
}

$text = [IO.File]::ReadAllText($Record)
$found = [regex]::Matches($text, '(?m)^Baseline: ([0-9a-f]{40})\r?$')
if ($found.Count -ne 1) { throw "UPSTREAM.md must contain exactly one 'Baseline: <40-character sha>' line." }
$baseline = $found[0].Groups[1].Value

# Pull-only: the upstream remote gets an invalid push URL, so a push to it always fails.
if (@(Invoke-Git remote) -contains 'upstream') { Invoke-Git remote set-url upstream $UpstreamUrl | Out-Null }
else { Invoke-Git remote add upstream $UpstreamUrl | Out-Null }
Invoke-Git remote set-url --push upstream no_push | Out-Null

# Only the two commits are needed for the diff, never upstream's history.
Write-Host "Fetching $To from upstream..."
Invoke-Git fetch --depth=1 --no-tags upstream $To | Out-Null
$target = "$(Invoke-Git rev-parse FETCH_HEAD | Select-Object -Last 1)".Trim()
if (-not (Test-Commit $baseline)) { Invoke-Git fetch --depth=1 --no-tags upstream $baseline | Out-Null }

if ($target -eq $baseline) {
    Write-Host "Already synced to $target; nothing to apply."
    exit 0
}

# Written by git itself: piping the diff through PowerShell would re-encode the translations.
$patch = Join-Path $Root '.git\upstream-sync.patch'
Invoke-Git diff --binary -M "--output=$patch" $baseline $target '--' @SyncedPaths | Out-Null
$conflicts = @()
if ((Get-Item $patch).Length -gt 0) {
    $ErrorActionPreference = 'Continue'
    $applyOut = & git -C $Root apply --3way --whitespace=nowarn $patch 2>&1 | ForEach-Object { "$_" }
    $applyExit = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    $conflicts = @(Invoke-Git diff --name-only --diff-filter=U)
    if ($applyExit -ne 0 -and -not $conflicts.Count) {
        throw "Upstream's changes could not be applied:`n$($applyOut -join "`n")"
    }
}
Remove-Item $patch -ErrorAction SilentlyContinue

$from = $baseline.Substring(0, 7); $until = $target.Substring(0, 7)
$text = $text -replace '(?m)^Baseline: [0-9a-f]{40}', "Baseline: $target"
$text = $text.TrimEnd() + "`n- $(Get-Date -Format 'yyyy-MM-dd'): synced $from..$until ($target)`n"
[IO.File]::WriteAllText($Record, $text, (New-Object Text.UTF8Encoding $false))
Invoke-Git add UPSTREAM.md | Out-Null

$message = "Sync CleanYourTV $from..$until"
if ($conflicts.Count) {
    Write-Warning "Upstream's changes overlap ours in these files; resolve the <<<<<<< markers, then git add them:"
    $conflicts | ForEach-Object { Write-Host "  $_" }
    Write-Host "Then commit: git commit -m `"$message`""
    exit 1
}
Write-Host "Upstream's changes are applied and staged. Review with: git diff --cached --stat"
Write-Host "Build and test, then commit: git commit -m `"$message`""
