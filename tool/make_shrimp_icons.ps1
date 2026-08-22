# Gera os ícones do AQUACENSO (favicon + PWA/manifest) com um camarão.
# Desenho vetorial via System.Drawing; camarão coral sobre fundo verde da marca.
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

$bg = [System.Drawing.Color]::FromArgb(22, 163, 74)        # verde marca #16A34A
$corpo = [System.Drawing.Color]::FromArgb(239, 131, 84)     # coral #EF8354
$corpoEscuro = [System.Drawing.Color]::FromArgb(214, 108, 58) # coral escuro (contorno/detalhe)
$branco = [System.Drawing.Color]::White
$pupila = [System.Drawing.Color]::FromArgb(58, 38, 24)      # marrom-escuro

function New-Shrimp {
    param([int]$S)  # tamanho do quadrado (ex.: 512)

    $bmp = New-Object System.Drawing.Bitmap $S, $S
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

    $k = $S / 512.0  # escala

    # Fundo (verde da marca), cheio — bom para maskable e web.
    $g.Clear($bg)

    # --- Camarão: corpo de elipses sobrepostas em diagonal (cabeça → cauda) ---
    function Draw-Seg {
        param($g, $k, $cx, $cy, $rx, $ry, $cor)
        $b = New-Object System.Drawing.SolidBrush $cor
        $x = $cx * $k; $y = $cy * $k
        $w = $rx * $k; $h = $ry * $k
        $g.FillEllipse($b, $x - $w, $y - $h, 2 * $w, 2 * $h)
        $b.Dispose()
    }
    Draw-Seg $g $k 375 185 62 68 $corpo       # cabeça
    Draw-Seg $g $k 348 250 55 55 $corpo
    Draw-Seg $g $k 305 300 50 50 $corpo
    Draw-Seg $g $k 252 328 46 46 $corpo
    Draw-Seg $g $k 198 335 42 42 $corpo
    Draw-Seg $g $k 150 322 38 38 $corpo
    Draw-Seg $g $k 112 295 34 34 $corpoEscuro # base da cauda

    # --- Cauda (leque): duas aletas ---
    function Draw-Aleta {
        param($g, $k, $cx, $cy, $w, $h, $ang)
        $aletaBrush = New-Object System.Drawing.SolidBrush $corpo
        $aletaPath = New-Object System.Drawing.Drawing2D.GraphicsPath
        $x = $cx * $k; $y = $cy * $k
        $ww = $w * $k; $hh = $h * $k
        $aletaPath.AddEllipse($x - $ww, $y - $hh, 2 * $ww, 2 * $hh)
        $g.TranslateTransform($x, $y)
        $g.RotateTransform($ang)
        $g.FillPath($aletaBrush, $aletaPath)
        $g.ResetTransform()
        $aletaBrush.Dispose(); $aletaPath.Dispose()
    }
    Draw-Aleta $g $k 78 268 40 24 -25
    Draw-Aleta $g $k 78 305 44 26 20

    # --- Perinhas (patas curtas para baixo) ---
    $penPata = New-Object System.Drawing.Pen $corpoEscuro, (5 * $k)
    $penPata.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $penPata.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $g.DrawLine($penPata, 305 * $k, 348 * $k, 290 * $k, 402 * $k)
    $g.DrawLine($penPata, 262 * $k, 378 * $k, 248 * $k, 432 * $k)
    $g.DrawLine($penPata, 212 * $k, 378 * $k, 200 * $k, 428 * $k)
    $g.DrawLine($penPata, 164 * $k, 356 * $k, 152 * $k, 404 * $k)
    $penPata.Dispose()

    # --- Olho (branco + pupila) ---
    $eyeBrush = New-Object System.Drawing.SolidBrush $branco
    $g.FillEllipse($eyeBrush, 388 * $k, 140 * $k, 34 * $k, 34 * $k)
    $eyeBrush.Dispose()
    $pupilBrush = New-Object System.Drawing.SolidBrush $pupila
    $g.FillEllipse($pupilBrush, 393 * $k, 145 * $k, 18 * $k, 18 * $k)
    $pupilBrush.Dispose()

    # --- Antenas (duas curvas subindo da cabeça) ---
    $penAntena = New-Object System.Drawing.Pen $corpoEscuro, (5 * $k)
    $penAntena.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $penAntena.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    # curva 1
    $p1 = New-Object System.Drawing.Drawing2D.GraphicsPath
    $p1.AddBezier(
        (430 * $k), (150 * $k),
        (465 * $k), (110 * $k),
        (455 * $k), (70 * $k),
        (480 * $k), (38 * $k))
    $g.DrawPath($penAntena, $p1)
    $p1.Dispose()
    # curva 2
    $p2 = New-Object System.Drawing.Drawing2D.GraphicsPath
    $p2.AddBezier(
        (410 * $k), (160 * $k),
        (410 * $k), (110 * $k),
        (390 * $k), (80 * $k),
        (405 * $k), (40 * $k))
    $g.DrawPath($penAntena, $p2)
    $p2.Dispose()
    $penAntena.Dispose()

    $g.Dispose()
    return $bmp
}

function Save-Scaled {
    param($master, [string]$path, [int]$size)
    $dest = New-Object System.Drawing.Bitmap $size, $size
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

$master = New-Shrimp 512
Save-Scaled $master (Join-Path $web 'favicon.png') 64
Save-Scaled $master (Join-Path $icons 'Icon-512.png') 512
Save-Scaled $master (Join-Path $icons 'Icon-192.png') 192
Save-Scaled $master (Join-Path $icons 'Icon-maskable-512.png') 512
Save-Scaled $master (Join-Path $icons 'Icon-maskable-192.png') 192
$master.Dispose()

Write-Output 'Ícones gerados:'
Get-ChildItem (Join-Path $web 'favicon.png'), (Join-Path $icons '*.png') | Select-Object Name, Length | Format-Table -AutoSize
