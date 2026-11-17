<#
.SYNOPSIS
  Generate a 1200x630 Open Graph card from any screenshot/source image via
  cover-scale + center-crop (fills the frame, no letterboxing, no distortion).

.EXAMPLE
  powershell -File make-og-card.ps1 -Source C:\site\screenshot.png -Out C:\site\public\og.png
#>
param(
  [Parameter(Mandatory)][string]$Source,
  [string]$Out,
  [int]$Width = 1200,
  [int]$Height = 630
)
Add-Type -AssemblyName System.Drawing
if (-not $Out) { $Out = Join-Path (Split-Path -Parent $Source) 'og.png' }
$outDir = Split-Path -Parent $Out
if ($outDir -and -not (Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }
$src = [System.Drawing.Bitmap]::FromFile($Source)
$sw = $src.Width; $sh = $src.Height
$scale = [Math]::Max($Width/$sw, $Height/$sh)        # cover
$dw = [int]($sw*$scale); $dh = [int]($sh*$scale)
$ox = [int](($Width-$dw)/2); $oy = [int](($Height-$dh)/2)
$og = New-Object System.Drawing.Bitmap($Width,$Height)
$g = [System.Drawing.Graphics]::FromImage($og)
$g.InterpolationMode='HighQualityBicubic'; $g.PixelOffsetMode='HighQuality'
$g.DrawImage($src, (New-Object System.Drawing.Rectangle($ox,$oy,$dw,$dh))); $g.Dispose()
$og.Save($Out,[System.Drawing.Imaging.ImageFormat]::Png); $og.Dispose(); $src.Dispose()
"Saved $Out ($Width x $Height). Reference it as an ABSOLUTE url in og:image. Then cache-bust (Workflow C)."
