param([string]$Dir, [string]$Out, [int]$From = 1, [int]$To = 9, [int]$W = 220, [string]$Ext = 'jpg')
# Downscaled contact sheet of NN.<ext> diagrams with their number.
Add-Type -AssemblyName System.Drawing
$n = $To - $From + 1; $H = [int]($W * 1024 / 768)
$bmp = [Drawing.Bitmap]::new([int]($n * ($W + 6)), [int]($H + 26))
$g = [Drawing.Graphics]::FromImage($bmp); $g.Clear([Drawing.Color]::White)
$g.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$font = [Drawing.Font]::new('Arial', 14, [Drawing.FontStyle]::Bold)
for ($i = $From; $i -le $To; $i++) {
  $im = [Drawing.Image]::FromFile((Join-Path $Dir ('{0:D2}.{1}' -f $i, $Ext)))
  $x = ($i - $From) * ($W + 6)
  $g.DrawImage($im, $x, 24, $W, $H); $g.DrawString("$i", $font, [Drawing.Brushes]::Red, $x + 2, 2); $im.Dispose()
}
$bmp.Save($Out, [Drawing.Imaging.ImageFormat]::Jpeg)
