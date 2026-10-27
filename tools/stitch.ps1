param(
  [double]$Lat, [double]$Lng,
  [int]$Zoom = 17,
  [int]$Cols = 8, [int]$Rows = 8,
  [string]$Out,
  # Optional fixed top-left tile instead of centring on Lat/Lng.
  [int]$TileX = -1, [int]$TileY = -1,
  [int]$Quality = 85
)
# Stitches GSI seamless-photo tiles into one JPEG. Prints the top-left tile so pixel (x,y) in
# the image is tile (TileX + x/256, TileY + y/256) at this zoom.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$n = [math]::Pow(2, $Zoom)
if ($TileX -lt 0) {
  $r = $Lat * [math]::PI / 180
  $cx = ($Lng + 180) / 360 * $n
  $cy = (1 - [math]::Log([math]::Tan($r) + 1 / [math]::Cos($r)) / [math]::PI) / 2 * $n
  $TileX = [int][math]::Floor($cx - $Cols / 2); $TileY = [int][math]::Floor($cy - $Rows / 2)
}
$bmp = New-Object Drawing.Bitmap ($Cols * 256), ($Rows * 256)
$g = [Drawing.Graphics]::FromImage($bmp)
$g.Clear([Drawing.Color]::Black)
$wc = New-Object Net.WebClient
for ($x = 0; $x -lt $Cols; $x++) { for ($y = 0; $y -lt $Rows; $y++) {
  $u = "https://cyberjapandata.gsi.go.jp/xyz/seamlessphoto/$Zoom/$($TileX + $x)/$($TileY + $y).jpg"
  try { $ms = New-Object IO.MemoryStream(,$wc.DownloadData($u)); $img = [Drawing.Image]::FromStream($ms); $g.DrawImage($img, $x * 256, $y * 256, 256, 256); $img.Dispose() } catch { Write-Host "miss $u" }
} }
$enc = [Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object MimeType -eq 'image/jpeg'
$p = New-Object Drawing.Imaging.EncoderParameters 1
$p.Param[0] = [Drawing.Imaging.EncoderParameter]::new([Drawing.Imaging.Encoder]::Quality, [long]$Quality)
$bmp.Save($Out, $enc, $p)
"tileX=$TileX tileY=$TileY zoom=$Zoom size=$($Cols*256)x$($Rows*256)"
