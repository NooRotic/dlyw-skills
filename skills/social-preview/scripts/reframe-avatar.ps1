<#
.SYNOPSIS
  Reframe a square (or circle-masked) source image into avatar variants that
  survive BOTH a circular avatar mask AND the 1.91:1 link-preview center-strip crop.

.DESCRIPTION
  Flattens any transparent corners onto a background color sampled from the top
  edge (above the subject = reliably background), then emits:
    whole_<name>.png : the full figure scaled to ~Scale of the square and centered
                       with even margin. SAFE for link previews -- the strip crop
                       keeps the whole subject because there is margin to spare.
    crop_<name>.png  : a tighter center head-and-shoulders zoom, for fixed
                       circle/square slots that never strip-crop.

.EXAMPLE
  powershell -File reframe-avatar.ps1 -Source C:\images\pfp.png -Mode both -Scale 0.52
#>
param(
  [Parameter(Mandatory)][string]$Source,
  [string]$OutDir,
  [ValidateRange(0.2,1.0)][double]$Scale = 0.52,   # whole-figure size within the square
  [int]$Size = 1024,
  [ValidateSet('whole','crop','both')][string]$Mode = 'both',
  [double]$CropFrac = 0.68                          # crop-mode zoom (fraction of min dimension)
)
Add-Type -AssemblyName System.Drawing
if (-not $OutDir) { $OutDir = Split-Path -Parent $Source }
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Force -Path $OutDir | Out-Null }
$src = [System.Drawing.Bitmap]::FromFile($Source)
$W = $src.Width; $H = $src.Height

# Sample background from the top arc (above the subject).
$r=0;$g=0;$b=0;$n=0
foreach ($fx in 0.40,0.45,0.50,0.55,0.60) {
  $p = $src.GetPixel([int]($W*$fx), [int]($H*0.012)); $r+=$p.R;$g+=$p.G;$b+=$p.B;$n++
}
$bg = [System.Drawing.Color]::FromArgb(255,[int]($r/$n),[int]($g/$n),[int]($b/$n))

# Flatten transparency onto bg.
$flat = New-Object System.Drawing.Bitmap($W,$H)
$gf = [System.Drawing.Graphics]::FromImage($flat)
$gf.Clear($bg); $gf.InterpolationMode='HighQualityBicubic'; $gf.DrawImage($src,0,0,$W,$H); $gf.Dispose()

$base = [IO.Path]::GetFileNameWithoutExtension($Source)
$out = @()

function New-Square { param($bgc) $b=New-Object System.Drawing.Bitmap($Size,$Size); $gr=[System.Drawing.Graphics]::FromImage($b); $gr.Clear($bgc); $gr.InterpolationMode='HighQualityBicubic'; $gr.PixelOffsetMode='HighQuality'; ,$b,$gr }

if ($Mode -in 'whole','both') {
  $c,$gc = New-Square $bg
  $sz = [int]($Size*$Scale); $off = [int](($Size-$sz)/2)
  $gc.DrawImage($flat, (New-Object System.Drawing.Rectangle($off,$off,$sz,$sz))); $gc.Dispose()
  $p = Join-Path $OutDir "whole_$base.png"; $c.Save($p,[System.Drawing.Imaging.ImageFormat]::Png); $c.Dispose(); $out += $p
}
if ($Mode -in 'crop','both') {
  $side = [int]([Math]::Min($W,$H)*$CropFrac)
  $cx = [int](($W-$side)/2); $cy = [int]($H*0.04)          # slight top bias for head-and-shoulders
  if ($cy + $side -gt $H) { $cy = $H - $side }
  $c,$gc = New-Square $bg
  $gc.DrawImage($flat, (New-Object System.Drawing.Rectangle(0,0,$Size,$Size)), $cx,$cy,$side,$side, [System.Drawing.GraphicsUnit]::Pixel); $gc.Dispose()
  $p = Join-Path $OutDir "crop_$base.png"; $c.Save($p,[System.Drawing.Imaging.ImageFormat]::Png); $c.Dispose(); $out += $p
}
$flat.Dispose(); $src.Dispose()
"Sampled bg: R=$($bg.R) G=$($bg.G) B=$($bg.B)"
"Saved: " + ($out -join ', ')
"Next: run preview-strip.ps1 on the whole_ variant to confirm the head survives the 1.91:1 crop."
