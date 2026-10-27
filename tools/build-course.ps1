param(
  [string]$Dir,            # work folder holding holes.json, official/NN.jpg
  [string]$Key,            # asset folder name, e.g. kaho
  [string]$Id, [string]$Name, [string]$Address, [string]$SourceUrl, [string]$DiagramSource,
  [int]$TileX, [int]$TileY, [int]$Cols, [int]$Rows,   # z17 overview tiles
  [int]$OffsetX = 0, [int]$OffsetY = 0,                # holes.json aerial coords minus this = overview coords
  [string]$Pars, [string]$Yards, [string]$Hdcp,        # comma separated, 18 values
  [string]$YardageLabel = 'WHITE',                     # tee name shown with the yardage
  [string]$Ext = 'jpg',                                # extension of official/NN.<ext>
  [string]$Out                                         # assets-<key>.json
)
# Builds one built-in course as a standalone asset bundle: overview photo, z18 detail tiles,
# hole diagrams, course.json, hole-geometry.json and aerial.json, all as data: URIs.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$utf8 = New-Object Text.UTF8Encoding $false
$assets = [ordered]@{}
function Add-Bytes([string]$k, [byte[]]$b, [string]$mime) { $assets[$k] = "data:$mime;base64," + [Convert]::ToBase64String($b) }
function Add-Json([string]$k, $obj) { Add-Bytes $k ($utf8.GetBytes(($obj | ConvertTo-Json -Depth 8 -Compress))) 'application/json' }
function Jpeg([Drawing.Image]$img, [long]$q) {
  # Flatten onto white first: transparent PNG areas would otherwise turn black in JPEG.
  $flat = [Drawing.Bitmap]::new($img.Width, $img.Height); $fg = [Drawing.Graphics]::FromImage($flat)
  $fg.Clear([Drawing.Color]::White); $fg.DrawImage($img, 0, 0, $img.Width, $img.Height)
  $enc = [Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object MimeType -eq 'image/jpeg'
  $p = New-Object Drawing.Imaging.EncoderParameters 1; $p.Param[0] = [Drawing.Imaging.EncoderParameter]::new([Drawing.Imaging.Encoder]::Quality, $q)
  $ms = New-Object IO.MemoryStream; $flat.Save($ms, $enc, $p); $ms.ToArray()
}
$wc = New-Object Net.WebClient

# Overview photo (z17)
$bmp = [Drawing.Bitmap]::new($Cols * 256, $Rows * 256); $g = [Drawing.Graphics]::FromImage($bmp)
for ($x = 0; $x -lt $Cols; $x++) { for ($y = 0; $y -lt $Rows; $y++) {
  $ms = New-Object IO.MemoryStream(,$wc.DownloadData("https://cyberjapandata.gsi.go.jp/xyz/seamlessphoto/17/$($TileX + $x)/$($TileY + $y).jpg"))
  $im = [Drawing.Image]::FromStream($ms); $g.DrawImage($im, $x * 256, $y * 256, 256, 256); $im.Dispose()
} }
Add-Bytes "./$Key/aerial.jpg" (Jpeg $bmp 82) 'image/jpeg'

# z18 detail tiles over the same area
$n18 = 0
for ($x = 2 * $TileX; $x -lt 2 * ($TileX + $Cols); $x++) { for ($y = 2 * $TileY; $y -lt 2 * ($TileY + $Rows); $y++) {
  try { Add-Bytes "./aerial-tiles/18/$x/$y.jpg" ($wc.DownloadData("https://cyberjapandata.gsi.go.jp/xyz/seamlessphoto/18/$x/$y.jpg")) 'image/jpeg'; $n18++ } catch {}
} }

$tile2lat = { param($ty, $z) [math]::Atan([math]::Sinh([math]::PI * (1 - 2 * $ty / [math]::Pow(2, $z)))) * 180 / [math]::PI }
$tile2lng = { param($tx, $z) $tx / [math]::Pow(2, $z) * 360 - 180 }
$bounds = @(@((& $tile2lat ($TileY + $Rows) 17), (& $tile2lng $TileX 17)), @((& $tile2lat $TileY 17), (& $tile2lng ($TileX + $Cols) 17)))
Add-Json "./$Key/aerial.json" ([ordered]@{ image = "./$Key/aerial.jpg"; bounds = $bounds; zoom = 17; tileX = $TileX; tileY = $TileY; size = @(($Cols * 256), ($Rows * 256)); source = 'https://maps.gsi.go.jp/development/ichiran.html'; attribution = '国土地理院（地理院タイル）'; retrievedAt = (Get-Date -Format 'yyyy-MM-dd') })

# Diagrams, course data and hole geometry
$par = $Pars -split ','; $yd = $Yards -split ','; $hc = $Hdcp -split ','
$spec = (Get-Content (Join-Path $Dir 'holes.json') -Raw | ConvertFrom-Json).holes
$holes = @(); $geo = @()
foreach ($h in $spec) {
  $nn = '{0:D2}' -f $h.n
  $im = [Drawing.Image]::FromFile((Join-Path $Dir "official\$nn.$Ext")); $size = @($im.Width, $im.Height)
  Add-Bytes "./$Key/$nn.jpg" (Jpeg $im 72) 'image/jpeg'; $im.Dispose()
  $i = $h.n - 1
  $holes += [ordered]@{ number = $h.n; side = $(if ($h.n -le 9) { 'OUT' } else { 'IN' }); par = [int]$par[$i]; handicap = [int]$hc[$i]; whiteYards = [int]$yd[$i]; image = "./$Key/$nn.jpg"; diagramSize = $size }
  $shift = { param($p) @(($p[0] - $OffsetX), ($p[1] - $OffsetY)) }
  # Optional dogleg point (diagram IP <-> aerial bend) between tee and green.
  $pts = @(, (& $shift $h.tee)); $anchors = @([ordered]@{ kind = 'tee'; diagram = $h.dTee; aerial = (& $shift $h.tee) })
  if ($h.bend) { $pts += , (& $shift $h.bend); $anchors += [ordered]@{ kind = 'fairway'; diagram = $h.dBend; aerial = (& $shift $h.bend) } }
  $pts += , (& $shift $h.green); $anchors += [ordered]@{ kind = 'green'; diagram = $h.dGreen; aerial = (& $shift $h.green) }
  # Corridor outline along tee-(bend)-green: a rough marker of the hole, not a boundary.
  $w = 30; $left = @(); $right = @()
  for ($k = 0; $k -lt $pts.Count; $k++) {
    $a = $pts[[math]::Max(0, $k - 1)]; $b = $pts[[math]::Min($pts.Count - 1, $k + 1)]
    $dx = $b[0] - $a[0]; $dy = $b[1] - $a[1]; $len = [math]::Sqrt($dx * $dx + $dy * $dy); $ux = $dx / $len; $uy = $dy / $len
    $reach = $(if ($k -eq 0) { -15 } elseif ($k -eq $pts.Count - 1) { 10 } else { 0 })
    $px = $pts[$k][0] + $ux * $reach; $py = $pts[$k][1] + $uy * $reach
    $left += , @([int]($px - $uy * $w), [int]($py + $ux * $w)); $right = , @([int]($px + $uy * $w), [int]($py - $ux * $w)) + $right
  }
  $outline = $left + $right
  $geo += [ordered]@{ number = $h.n; approximate = $true; confidence = $(if ($h.low) { 'low' } else { 'approximate' }); diagramSize = $size
    anchors = $anchors; outlineAerial = $outline; outlineIsBoundary = $false }
}
Add-Json "./$Key/course.json" ([ordered]@{ id = $Id; name = $Name; address = $Address; sourceUrl = $SourceUrl; yardageLabel = $YardageLabel; retrievedAt = (Get-Date -Format 'yyyy-MM-dd'); holes = $holes })
Add-Json "./$Key/hole-geometry.json" ([ordered]@{ aerialSize = @(($Cols * 256), ($Rows * 256)); approximate = $true; method = 'Tee and green centre read manually from GSI orthophoto against the official per-hole diagrams and a third-party course overview. Outline is a corridor around the tee-green line, not a boundary.'; sources = @($DiagramSource, 'https://maps.gsi.go.jp/development/ichiran.html'); checkedAt = (Get-Date -Format 'yyyy-MM-dd'); holes = $geo })

$json = '{' + (($assets.GetEnumerator() | ForEach-Object { '"' + $_.Key + '":"' + $_.Value + '"' }) -join ',') + '}'
[IO.File]::WriteAllText($Out, $json, $utf8)
'assets: {0} (z18 tiles: {1})  size: {2:N1} MB' -f $assets.Count, $n18, ((Get-Item $Out).Length / 1MB)
