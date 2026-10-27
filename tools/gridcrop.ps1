param([string]$In, [string]$Out, [int]$X, [int]$Y, [int]$Wd, [int]$Ht, [int]$Step = 50, [double]$Scale = 1)
# Crops a region and draws a labelled grid in the SOURCE image's pixel coordinates.
Add-Type -AssemblyName System.Drawing
$src = [Drawing.Image]::FromFile($In)
$ow = [int]($Wd * $Scale); $oh = [int]($Ht * $Scale)
$bmp = [Drawing.Bitmap]::new($ow, $oh); $g = [Drawing.Graphics]::FromImage($bmp)
$g.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.DrawImage($src, [Drawing.Rectangle]::new(0, 0, $ow, $oh), [Drawing.Rectangle]::new($X, $Y, $Wd, $Ht), [Drawing.GraphicsUnit]::Pixel)
$pen = [Drawing.Pen]::new([Drawing.Color]::FromArgb(110, 255, 255, 0), 1)
$font = [Drawing.Font]::new('Arial', 9, [Drawing.FontStyle]::Bold)
for ($gx = [math]::Ceiling($X / $Step) * $Step; $gx -lt $X + $Wd; $gx += $Step) { $p = ($gx - $X) * $Scale; $g.DrawLine($pen, $p, 0, $p, $oh); $g.DrawString("$gx", $font, [Drawing.Brushes]::Yellow, $p + 1, 1) }
for ($gy = [math]::Ceiling($Y / $Step) * $Step; $gy -lt $Y + $Ht; $gy += $Step) { $p = ($gy - $Y) * $Scale; $g.DrawLine($pen, 0, $p, $ow, $p); $g.DrawString("$gy", $font, [Drawing.Brushes]::Cyan, 1, $p + 1) }
$bmp.Save($Out, [Drawing.Imaging.ImageFormat]::Jpeg)
