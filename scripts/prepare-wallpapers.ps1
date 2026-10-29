# Turns a folder of images into a theme's wallpaper collection (<theme>\wallpapers): 1920x1080 JPEGs, darkened
# where the dock and the clock sit, at most -MaxKB each, with names the launcher accepts. -Captions also writes
# captions.txt from the source file names. Source images are never changed.
param(
    [Parameter(Mandatory)][string]$Source,
    [Parameter(Mandatory)][string]$Theme,
    # Which side of a too-wide picture to keep.
    [ValidateSet('left', 'center', 'right')][string]$Anchor = 'center',
    # Largest file per wallpaper. 300 matches CleanYourTV's guidance for bundled themes; a private theme can
    # afford more, since file size never changes the TV's memory (every wallpaper decodes to 1920x1080).
    [ValidateRange(50, 4096)][int]$MaxKB = 300,
    [switch]$Captions
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$Width = 1920; $Height = 1080
$MaxBytes = $MaxKB * 1KB
$SoftBelow = 1280          # source pixels across the crop; fewer look soft on a 1080p screen
$Supported = @('.jpg', '.jpeg', '.png', '.bmp', '.gif')
$MaxCaption = 80           # the launcher cuts longer captions anyway
# Darkening, tuned on the TV: a fade to black toward the bottom edge (the dock), and a soft corner at the top
# left (greeting, clock and date).
$BottomFrom = 0.55; $BottomAlpha = 178                    # from 55% of the height down to 70% black
$CornerAlpha = 140; $CornerWidth = 0.40; $CornerHeight = 0.55   # 55% black, fading out across this much

# Paths resolve against PowerShell's location, not the process's, so relative arguments work as typed.
function Get-FullPath([string]$Path) { $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path).TrimEnd('\') }
$sourceDir = Get-FullPath $Source
$targetDir = Get-FullPath (Join-Path $Theme 'wallpapers')
if (-not (Test-Path -LiteralPath $sourceDir -PathType Container)) { throw "Source folder not found: $Source" }
if ($sourceDir -ieq $targetDir) { throw "The source folder is the theme's own wallpapers folder; pick a separate folder for the originals. Nothing was changed." }

# Decoded from memory so the source file is never held open or written.
function Read-Image([string]$Path) {
    $stream = New-Object IO.MemoryStream(, [IO.File]::ReadAllBytes($Path))
    try { [System.Drawing.Image]::FromStream($stream) } catch { $stream.Dispose(); $null }
}

# Lower-case ASCII letters, digits and dashes, accents dropped: "Sao Paulo at night" (with a tilde) -> sao-paulo-at-night.
function Get-Slug([string]$Name) {
    $plain = New-Object Text.StringBuilder
    foreach ($ch in $Name.Normalize([Text.NormalizationForm]::FormD).ToCharArray()) {
        if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($ch) -ne 'NonSpacingMark') { [void]$plain.Append($ch) }
    }
    $slug = ($plain.ToString().ToLowerInvariant() -replace '[^a-z0-9]+', '-').Trim('-')
    if ($slug.Length -gt 40) { $slug = $slug.Substring(0, 40).TrimEnd('-') }
    if ($slug) { $slug } else { 'image' }
}

# Everything is checked before the target is touched, so a folder with nothing usable changes nothing.
$sources = @()
foreach ($file in Get-ChildItem -LiteralPath $sourceDir -File | Sort-Object Name) {
    if ($Supported -notcontains $file.Extension.ToLowerInvariant()) {
        $hint = if ($file.Extension -ieq '.webp') { ' Convert it to JPEG or PNG first.' } else { '' }
        Write-Host "Skipped $($file.Name): not a JPEG, PNG, BMP or GIF.$hint"
        continue
    }
    $probe = Read-Image $file.FullName
    if (-not $probe) { Write-Host "Skipped $($file.Name): Windows can't read it (a CMYK JPEG? re-save it as RGB JPEG or PNG)."; continue }
    $probe.Dispose()
    $sources += $file
}
if (-not $sources.Count) { throw "No usable images in $Source. Nothing was written." }

New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
Get-ChildItem -LiteralPath $targetDir -File |
    Where-Object { $_.Extension -match '^\.(jpg|jpeg|png|webp)$' -or $_.Name -eq 'captions.txt' } |
    Remove-Item -Force

$jpeg = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
$digits = if ($sources.Count -gt 99) { 3 } else { 2 }
$captionLines = @()
$written = 0
foreach ($file in $sources) {
    # Numbered only once written, so a skipped picture leaves no gap.
    $name = ('{0:D' + $digits + '}-{1}.jpg') -f ($written + 1), (Get-Slug $file.BaseName)
    $image = Read-Image $file.FullName
    $frame = New-Object System.Drawing.Bitmap($Width, $Height, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $g = [System.Drawing.Graphics]::FromImage($frame)
    try {
        # Cover the frame: scale until both sides fill it, then crop the overflow by the anchor.
        $scale = [Math]::Max($Width / $image.Width, $Height / $image.Height)
        $cropW = $Width / $scale; $cropH = $Height / $scale
        $x = switch ($Anchor) { 'left' { 0 } 'right' { $image.Width - $cropW } default { ($image.Width - $cropW) / 2 } }
        $y = ($image.Height - $cropH) / 2
        if ($cropW -lt $SoftBelow) { Write-Warning "$($file.Name) is only $([int]$cropW) pixels across after cropping; it will look soft on the TV." }

        $g.Clear([System.Drawing.Color]::Black)   # transparent pixels end up black
        $g.InterpolationMode = 'HighQualityBicubic'; $g.PixelOffsetMode = 'HighQuality'
        $g.CompositingQuality = 'HighQuality'; $g.SmoothingMode = 'HighQuality'
        $edges = New-Object System.Drawing.Imaging.ImageAttributes
        $edges.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)   # no dark seam along the edges
        $g.DrawImage($image, (New-Object System.Drawing.Rectangle(0, 0, $Width, $Height)),
            [float]$x, [float]$y, [float]$cropW, [float]$cropH, [System.Drawing.GraphicsUnit]::Pixel, $edges)

        $top = [int]($Height * $BottomFrom)
        $fade = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            (New-Object System.Drawing.Point(0, ($top - 1))), (New-Object System.Drawing.Point(0, ($Height + 1))),
            [System.Drawing.Color]::FromArgb(0, 0, 0, 0), [System.Drawing.Color]::FromArgb($BottomAlpha, 0, 0, 0))
        $g.FillRectangle($fade, 0, $top, $Width, $Height - $top)
        $fade.Dispose()

        $rx = $Width * $CornerWidth; $ry = $Height * $CornerHeight
        $corner = New-Object System.Drawing.Drawing2D.GraphicsPath
        $corner.AddEllipse([float](-$rx), [float](-$ry), [float](2 * $rx), [float](2 * $ry))
        $glow = New-Object System.Drawing.Drawing2D.PathGradientBrush($corner)
        $glow.CenterPoint = New-Object System.Drawing.PointF(0, 0)
        $glow.CenterColor = [System.Drawing.Color]::FromArgb($CornerAlpha, 0, 0, 0)
        $glow.SurroundColors = @([System.Drawing.Color]::FromArgb(0, 0, 0, 0))
        $g.FillPath($glow, $corner)
        $glow.Dispose(); $corner.Dispose()

        # The highest JPEG quality that fits the size limit.
        $bytes = $null
        for ($quality = 90; $quality -ge 50; $quality -= 5) {
            $params = New-Object System.Drawing.Imaging.EncoderParameters(1)
            $params.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]$quality)
            $buffer = New-Object IO.MemoryStream
            $frame.Save($buffer, $jpeg, $params)
            if ($buffer.Length -le $MaxBytes) { $bytes = $buffer.ToArray(); break }
        }
        if ($bytes) {
            [IO.File]::WriteAllBytes((Join-Path $targetDir $name), $bytes)
            Write-Host ('{0} -> {1} ({2} KB, quality {3})' -f $file.Name, $name, [Math]::Round($bytes.Length / 1KB), $quality)
        }
    } finally {
        $g.Dispose(); $frame.Dispose(); $image.Dispose()
    }
    if (-not $bytes) {
        Write-Warning "Skipped $($file.Name): still over $MaxKB KB at JPEG quality 50. Raise -MaxKB or use a simpler picture."
        continue
    }
    $written++

    $caption = $file.BaseName.Trim()
    if ($caption.Length -gt $MaxCaption) { $caption = $caption.Substring(0, $MaxCaption).Trim() }
    $captionLines += "$name`t$caption"
}

if ($Captions) {
    [IO.File]::WriteAllText((Join-Path $targetDir 'captions.txt'), (($captionLines -join "`n") + "`n"), (New-Object Text.UTF8Encoding $false))
}
Write-Host "Prepared $written of $($sources.Count) wallpapers in $targetDir$(if ($Captions) { ', with captions.txt' })."
