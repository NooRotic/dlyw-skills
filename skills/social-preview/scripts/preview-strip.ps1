<#
.SYNOPSIS
  Simulate a link-preview center-strip crop (default 1.91:1, LinkedIn/Twitter large card)
  on a candidate image so you can confirm the subject survives BEFORE uploading.

.EXAMPLE
  powershell -File preview-strip.ps1 -Source C:\images\whole_pfp.png
#>
param(
  [Parameter(Mandatory)][string]$Source,
  [string]$Out,
  [double]$Ratio = 1.91
)
Add-Type -AssemblyName System.Drawing
if (-not $Out) { $Out = Join-Path (Split-Path -Parent $Source) ("_preview_strip_" + [IO.Path]::GetFileName($Source)) }
$outDir = Split-Path -Parent $Out
if ($outDir -and -not (Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }
$img = [System.Drawing.Bitmap]::FromFile($Source)
$W = $img.Width
$bandH = [int]($W / $Ratio)
if ($bandH -gt $img.Height) { $bandH = $img.Height }
$y0 = [int](($img.Height - $bandH) / 2)
$strip = New-Object System.Drawing.Bitmap($W,$bandH)
$gs = [System.Drawing.Graphics]::FromImage($strip)
$gs.DrawImage($img, (New-Object System.Drawing.Rectangle(0,0,$W,$bandH)), 0,$y0,$W,$bandH, [System.Drawing.GraphicsUnit]::Pixel); $gs.Dispose()
$strip.Save($Out,[System.Drawing.Imaging.ImageFormat]::Png); $strip.Dispose(); $img.Dispose()
"Saved $Out (simulated $Ratio`:1 center-strip). Open it: if the head/subject is clipped, lower -Scale in reframe-avatar.ps1 and regenerate."
