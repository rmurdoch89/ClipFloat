$startup = [System.Environment]::GetFolderPath("Startup")
Copy-Item "C:\Users\Rob\ClaudeSnips\FloatingSnip.bat" "$startup\FloatingSnip.bat" -Force
Write-Host "Added ClipFloat to startup: $startup\FloatingSnip.bat"
