$ws = New-Object -ComObject WScript.Shell
$sc = $ws.CreateShortcut("$env:USERPROFILE\Desktop\PasteSnip.lnk")
$sc.TargetPath = "$env:USERPROFILE\ClaudeSnips\PasteSnip.bat"
$sc.WorkingDirectory = "$env:USERPROFILE\ClaudeSnips"
$sc.Description = "Save clipboard snip for Claude Code"
$sc.Save()
Write-Host "Desktop shortcut created." -ForegroundColor Green
