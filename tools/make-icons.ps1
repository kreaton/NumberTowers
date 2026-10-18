# Generates the app / home-screen icons for Number Towers.
# Run with Windows PowerShell (System.Drawing):  powershell -File tools\make-icons.ps1
param([string]$OutDir = (Join-Path $PSScriptRoot "..\src\NumberTowers\wwwroot\icons"))

Add-Type -AssemblyName System.Drawing
New-Item -ItemType Directory -Force $OutDir | Out-Null

function New-RoundedRect([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $r * 2
    $p.AddArc($x, $y, $d, $d, 180, 90)
    $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $p.CloseFigure()
    return $p
}

function Color([string]$hex) { [System.Drawing.ColorTranslator]::FromHtml($hex) }

# content: 1.0 = full bleed, 0.78 = keep inside the maskable safe zone
function Draw-Icon([int]$size, [string]$file, [float]$content = 1.0, [bool]$numbers = $true) {
    $S = [float]$size
    $bmp = New-Object System.Drawing.Bitmap $size, $size
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $g.TextRenderingHint = 'AntiAliasGridFit'
    $g.InterpolationMode = 'HighQualityBicubic'

    # Sky (full square, iOS applies its own rounded mask)
    $sky = New-Object System.Drawing.Drawing2D.LinearGradientBrush (New-Object System.Drawing.PointF 0, 0), (New-Object System.Drawing.PointF 0, $S), (Color '#5bb8ff'), (Color '#d4f0ff')
    $g.FillRectangle($sky, 0, 0, $S, $S)

    # Sun
    $sun = New-Object System.Drawing.SolidBrush (Color '#ffd84d')
    $g.FillEllipse($sun, $S * 0.07, $S * 0.07, $S * 0.2, $S * 0.2)

    # Grass
    $grassTop = $S * (0.5 + 0.34 * $content)
    $grass = New-Object System.Drawing.SolidBrush (Color '#6fcf4a')
    $g.FillRectangle($grass, 0, $grassTop, $S, $S - $grassTop)
    $grassHi = New-Object System.Drawing.SolidBrush (Color '#8ee06a')
    $g.FillRectangle($grassHi, 0, $grassTop, $S, $S * 0.018)

    # Towers
    $towers = @(
        @{ c = '#3b82f6'; d = '#1d4ed8'; n = 4; t = 'White' },
        @{ c = '#ef4444'; d = '#b91c1c'; n = 6; t = 'White' },
        @{ c = '#22c55e'; d = '#15803d'; n = 5; t = 'White' },
        @{ c = '#facc15'; d = '#ca8a04'; n = 7; t = '#6b3e00' }
    )
    $bw = $S * 0.165 * $content
    $bh = $S * 0.082 * $content
    $gap = $S * 0.035 * $content
    $vgap = $S * 0.012 * $content
    $total = 4 * $bw + 3 * $gap
    $x0 = ($S - $total) / 2
    $fontPx = [Math]::Max(1, $bh * 0.72)
    $font = New-Object System.Drawing.Font 'Arial Rounded MT Bold', $fontPx, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
    if ($font.Name -ne 'Arial Rounded MT Bold') {
        $font = New-Object System.Drawing.Font 'Segoe UI', $fontPx, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
    }
    $fmt = New-Object System.Drawing.StringFormat
    $fmt.Alignment = 'Center'
    $fmt.LineAlignment = 'Center'

    for ($i = 0; $i -lt 4; $i++) {
        $t = $towers[$i]
        $x = $x0 + $i * ($bw + $gap)
        $fill = New-Object System.Drawing.SolidBrush (Color $t.c)
        $dark = New-Object System.Drawing.SolidBrush (Color $t.d)
        $hi = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(90, 255, 255, 255))
        $txt = New-Object System.Drawing.SolidBrush (Color $t.t)
        for ($f = 0; $f -lt $t.n; $f++) {
            $y = $grassTop - ($f + 1) * ($bh + $vgap)
            $r = $bh * 0.22
            $g.FillPath($dark, (New-RoundedRect $x $y $bw $bh $r))
            $g.FillPath($fill, (New-RoundedRect $x $y $bw ($bh * 0.84) $r))
            $g.FillRectangle($hi, $x + $r, $y + $bh * 0.08, $bw - 2 * $r, $bh * 0.12)
            if ($numbers) {
                $rect = New-Object System.Drawing.RectangleF $x, ($y + $bh * 0.02), $bw, ($bh * 0.84)
                $g.DrawString(($f + 1).ToString(), $font, $txt, $rect, $fmt)
            }
        }
        # Studs on the top brick
        $topY = $grassTop - $t.n * ($bh + $vgap)
        $sw = $bw * 0.24; $sh = $bh * 0.22
        $g.FillRectangle($fill, $x + $bw * 0.16, $topY - $sh, $sw, $sh)
        $g.FillRectangle($fill, $x + $bw * 0.84 - $sw, $topY - $sh, $sw, $sh)
    }

    $g.Dispose()
    $bmp.Save((Join-Path $OutDir $file), [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "  $file"
}

Write-Host "Writing icons to $OutDir"
Draw-Icon 180  'apple-touch-icon.png'
Draw-Icon 167  'apple-touch-icon-167.png'
Draw-Icon 152  'apple-touch-icon-152.png'
Draw-Icon 120  'apple-touch-icon-120.png'
Draw-Icon 192  'icon-192.png'
Draw-Icon 512  'icon-512.png'
Draw-Icon 1024 'icon-1024.png'
Draw-Icon 512  'icon-512-maskable.png' 0.78
Draw-Icon 32   'favicon-32.png' 1.0 $false
