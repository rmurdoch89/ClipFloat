Add-Type -AssemblyName System.Windows.Forms

$img = [System.Windows.Forms.Clipboard]::GetImage()

if ($null -eq $img) {
    Write-Host ""
    Write-Host "  No image found on clipboard." -ForegroundColor Red
    Write-Host "  Use Win+Shift+S to snip your screen first, then run this again." -ForegroundColor Yellow
    Write-Host ""
    pause
    exit 1
}

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$filePath = "C:\Users\Rob\ClaudeSnips\snip_$timestamp.png"

$img.Save($filePath, [System.Drawing.Imaging.ImageFormat]::Png)
$img.Dispose()

# Copy the file path to clipboard so user can paste it into Claude Code
Set-Clipboard -Value $filePath

Write-Host ""
Write-Host "  Snip saved and path copied to clipboard!" -ForegroundColor Green
Write-Host ""
Write-Host "  File: $filePath" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Just paste (Ctrl+V) into Claude Code to share the screenshot." -ForegroundColor White
Write-Host ""
pause
