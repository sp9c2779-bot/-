param([string]$In, [string]$Json, [string]$Out, [double]$Scale = 0.6)
# Draws tee->green lines with hole numbers over the stitched aerial for a visual check.
Add-Type -AssemblyName System.Drawing
$src = [Drawing.Image]::FromFile($In); $d = Get-Content $Json -Raw | ConvertFrom-Json
$w = [int]($src.Width * $Scale); $h = [int]($src.Height * $Scale)
$bmp = [Drawing.Bitmap]::new($w, $h); $g = [Drawing.Graphics]::FromImage($bmp)
$g.DrawImage($src, 0, 0, $w, $h)
$pen = [Drawing.Pen]::new([Drawing.Color]::Yellow, 3); $font = [Drawing.Font]::new('Arial', 16, [Drawing.FontStyle]::Bold)
foreach ($o in $d.holes) {
  $tx = $o.tee[0] * $Scale; $ty = $o.tee[1] * $Scale; $gx = $o.green[0] * $Scale; $gy = $o.green[1] * $Scale
  $g.DrawLine($pen, [float]$tx, [float]$ty, [float]$gx, [float]$gy)
  $g.FillEllipse([Drawing.Brushes]::Cyan, [float]($tx - 5), [float]($ty - 5), 10, 10)
  $g.FillEllipse([Drawing.Brushes]::Red, [float]($gx - 6), [float]($gy - 6), 12, 12)
  $g.DrawString("$($o.n)", $font, [Drawing.Brushes]::White, [float](($tx + $gx) / 2 + 4), [float](($ty + $gy) / 2 - 10))
}
$bmp.Save($Out, [Drawing.Imaging.ImageFormat]::Jpeg)
