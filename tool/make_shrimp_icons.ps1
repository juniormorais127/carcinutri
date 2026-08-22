# Gera os ícones do AQUACENSO: só o formato do camarão (fundo transparente),
# com corpo segmentado (contorno branco) pra parecer um desenho vetorial limpo.
Add-Type -AssemblyName System.Drawing

$corpo = [System.Drawing.Color]::FromArgb(239, 131, 84)        # coral #EF8354
$corpoEscuro = [System.Drawing.Color]::FromArgb(214, 108, 58)   # coral escuro (cauda/patas/antenas)
$branco = [System.Drawing.Color]::White
$pupila = [System.Drawing.Color]::FromArgb(58, 38, 24)          # marrom-escuro

# Desenha o camarão na escala S (coordenadas definidas num "grid" de 512).
function New-Shrimp {
    param([int]$S)
    $k = $S / 512.0

    $bmp = New-Object System.Drawing.Bitmap $S, $S, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.Clear([System.Drawing.Color]::Transparent)  # fundo transparente

    $penOut = New-Object System.Drawing.Pen $branco, (7 * $k)
    $penOut.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round

    # --- Corpo segmentado: elipse coral + contorno branco (dá o visual de cauda) ---
    function Draw-Seg {
        param($g, $k, $pen, $cx, $cy, $rx, $ry, $cor)
        $x = $cx * $k; $y = $cy * $k; $w = $rx * $k; $h = $ry * $k
        $b = New-Object System.Drawing.SolidBrush $cor
        $g.FillEllipse($b, $x - $w, $y - $h, 2 * $w, 2 * $h)
        $b.Dispose()
        $g.DrawEllipse($pen, $x - $w, $y - $h, 2 * $w, 2 * $h)
    }
    Draw-Seg $g $k $penOut 375 185 62 68 $corpo          # cabeça
    Draw-Seg $g $k $penOut 348 250 55 55 $corpo
    Draw-Seg $g $k $penOut 305 300 50 50 $corpo
    Draw-Seg $g $k $penOut 252 328 46 46 $corpo
    Draw-Seg $g $k $penOut 198 335 42 42 $corpo
    Draw-Seg $g $k $penOut 150 322 38 38 $corpo
    Draw-Seg $g $k $penOut 112 295 34 34 $corpoEscuro     # base da cauda

    # --- Cauda (leque): duas aletas com contorno ---
    function Draw-Aleta {
        param($g, $k, $pen, $cx, $cy, $w, $h, $ang)
        $x = $cx * $k; $y = $cy * $k; $ww = $w * $k; $hh = $h * $k
        $path = New-Object System.Drawing.Drawing2D.GraphicsPath
        $path.AddEllipse($x - $ww, $y - $hh, 2 * $ww, 2 * $hh)
        $g.TranslateTransform($x, $y)
        $g.RotateTransform($ang)
        $b = New-Object System.Drawing.SolidBrush $corpo
        $g.FillPath($b, $path); $b.Dispose()
        $g.DrawPath($pen, $path)
        $g.ResetTransform()
        $path.Dispose()
    }
    Draw-Aleta $g $k $penOut 78 268 40 24 -25
    Draw-Aleta $g $k $penOut 78 305 44 26 20

    # --- Perinhas (patas curtas para baixo) ---
    $penPata = New-Object System.Drawing.Pen $corpoEscuro, (5 * $k)
    $penPata.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $penPata.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $g.DrawLine($penPata, 305 * $k, 348 * $k, 290 * $k, 402 * $k)
    $g.DrawLine($penPata, 262 * $k, 378 * $k, 248 * $k, 432 * $k)
    $g.DrawLine($penPata, 212 * $k, 378 * $k, 200 * $k, 428 * $k)
    $g.DrawLine($penPata, 164 * $k, 356 * $k, 152 * $k, 404 * $k)
    $penPata.Dispose()

    # --- Olho ---
    $eye = New-Object System.Drawing.SolidBrush $branco
    $g.FillEllipse($eye, 386 * $k, 138 * $k, 36 * $k, 36 * $k)
    $eye.Dispose()
    $pupil = New-Object System.Drawing.SolidBrush $pupila
    $g.FillEllipse($pupil, 392 * $k, 144 * $k, 18 * $k, 18 * $k)
    $pupil.Dispose()

    # --- Antenas ---
    $penAntena = New-Object System.Drawing.Pen $corpoEscuro, (5 * $k)
    $penAntena.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $penAntena.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $p1 = New-Object System.Drawing.Drawing2D.GraphicsPath
    $p1.AddBezier((430 * $k), (150 * $k), (465 * $k), (110 * $k), (455 * $k), (70 * $k), (480 * $k), (38 * $k))
    $g.DrawPath($penAntena, $p1); $p1.Dispose()
    $p2 = New-Object System.Drawing.Drawing2D.GraphicsPath
    $p2.AddBezier((410 * $k), (160 * $k), (410 * $k), (110 * $k), (390 * $k), (80 * $k), (405 * $k), (40 * $k))
    $g.DrawPath($penAntena, $p2); $p2.Dispose()
    $penAntena.Dispose()

    $penOut.Dispose()
    $g.Dispose()
    return $bmp
}

function Save-Scaled {
    param($master, [string]$path, [int]$size)
    $dest = New-Object System.Drawing.Bitmap $size, $size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($dest)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.DrawImage($master, 0, 0, $size, $size)
    $dest.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $dest.Dispose()
}

$root = Split-Path -Parent $PSScriptRoot
$web = Join-Path $root 'web'
$icons = Join-Path $web 'icons'

$master = New-Shrimp 1024
Save-Scaled $master (Join-Path $web 'favicon.png') 64
Save-Scaled $master (Join-Path $icons 'Icon-512.png') 512
Save-Scaled $master (Join-Path $icons 'Icon-192.png') 192
Save-Scaled $master (Join-Path $icons 'Icon-maskable-512.png') 512
Save-Scaled $master (Join-Path $icons 'Icon-maskable-192.png') 192
$master.Dispose()

Write-Output 'Ícones gerados (fundo transparente):'
Get-ChildItem (Join-Path $web 'favicon.png'), (Join-Path $icons '*.png') | Select-Object Name, Length | Format-Table -AutoSize
