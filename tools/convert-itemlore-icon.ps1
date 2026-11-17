param(
    [Parameter(Mandatory=$true)][string]$Source,
    [Parameter(Mandatory=$true)][string]$Destination
)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$image=[System.Drawing.Image]::FromFile((Resolve-Path -LiteralPath $Source))
$bitmap=[System.Drawing.Bitmap]::new(128,128,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics=[System.Drawing.Graphics]::FromImage($bitmap)
try {
    $graphics.CompositingMode=[System.Drawing.Drawing2D.CompositingMode]::SourceCopy
    $graphics.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.DrawImage($image,0,0,128,128)
    $stream=[System.IO.File]::Create($Destination)
    $writer=[System.IO.BinaryWriter]::new($stream)
    try {
        # Uncompressed BGRA TGA, top-left origin, 8-bit alpha.
        $header=[byte[]]::new(18)
        $header[2]=2; $header[12]=128; $header[14]=128; $header[16]=32; $header[17]=40
        $writer.Write($header)
        for($y=0;$y -lt 128;$y++) {
            for($x=0;$x -lt 128;$x++) {
                $pixel=$bitmap.GetPixel($x,$y)
                $writer.Write([byte[]]@($pixel.B,$pixel.G,$pixel.R,$pixel.A))
            }
        }
    } finally { $writer.Dispose() }
} finally { $graphics.Dispose(); $bitmap.Dispose(); $image.Dispose() }
