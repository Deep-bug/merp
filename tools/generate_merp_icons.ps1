param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

Add-Type -AssemblyName System.Drawing

$densities = @(
    @{ Dir = 'mipmap-mdpi'; Size = 48 },
    @{ Dir = 'mipmap-hdpi'; Size = 72 },
    @{ Dir = 'mipmap-xhdpi'; Size = 96 },
    @{ Dir = 'mipmap-xxhdpi'; Size = 144 },
    @{ Dir = 'mipmap-xxxhdpi'; Size = 192 }
)

function New-MerpIcon([int]$Size, [string]$OutputPath) {
    $bitmap = New-Object System.Drawing.Bitmap $Size, $Size
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

    $rect = New-Object System.Drawing.Rectangle 0, 0, $Size, $Size
    $gradient = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, ([System.Drawing.Color]::FromArgb(47, 128, 237)), ([System.Drawing.Color]::FromArgb(56, 189, 248)), 45
    $graphics.FillRectangle($gradient, $rect)

    $cloudBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(58, 255, 255, 255))
    $graphics.FillEllipse($cloudBrush, $Size * 0.45, $Size * 0.57, $Size * 0.34, $Size * 0.20)
    $graphics.FillEllipse($cloudBrush, $Size * 0.62, $Size * 0.48, $Size * 0.26, $Size * 0.23)
    $graphics.FillEllipse($cloudBrush, $Size * 0.75, $Size * 0.58, $Size * 0.22, $Size * 0.19)

    $titleFont = New-Object System.Drawing.Font 'Arial', ($Size * 0.19), ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
    $format = New-Object System.Drawing.StringFormat
    $format.Alignment = [System.Drawing.StringAlignment]::Center
    $format.LineAlignment = [System.Drawing.StringAlignment]::Center
    $graphics.DrawString('MERP', $titleFont, [System.Drawing.Brushes]::White, (New-Object System.Drawing.RectangleF 0, ($Size * 0.22), $Size, ($Size * 0.24)), $format)

    $badgeRect = New-Object System.Drawing.RectangleF ($Size * 0.24), ($Size * 0.62), ($Size * 0.52), ($Size * 0.18)
    $graphics.FillRectangle([System.Drawing.Brushes]::White, $badgeRect)
    $erpFont = New-Object System.Drawing.Font 'Arial', ($Size * 0.10), ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
    $erpBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(26, 103, 201))
    $graphics.DrawString('ERP', $erpFont, $erpBrush, $badgeRect, $format)

    $graphics.Dispose()
    $bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bitmap.Dispose()
}

$resRoot = Join-Path $ProjectRoot 'android\app\src\main\res'
foreach ($density in $densities) {
    $dir = Join-Path $resRoot $density.Dir
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    New-MerpIcon -Size $density.Size -OutputPath (Join-Path $dir 'ic_launcher.png')
}

Write-Host "MERP launcher icons generated under $resRoot"
