@echo off
echo.
echo  ===============================
echo   ClipFloat Installer
echo  ===============================
echo.

:: Get the directory where this script lives
set "SCRIPTDIR=%~dp0"

:: Add to Windows startup
echo  [1/3] Adding to Windows startup...
copy /Y "%SCRIPTDIR%FloatingSnip.bat" "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\FloatingSnip.bat" >nul 2>&1
if %errorlevel%==0 (
    echo        Done.
) else (
    echo        Warning: Could not add to startup.
)

:: Create desktop shortcut
echo  [2/3] Creating desktop shortcut...
powershell -ExecutionPolicy Bypass -Command "$ws = New-Object -ComObject WScript.Shell; $sc = $ws.CreateShortcut([System.IO.Path]::Combine($env:USERPROFILE, 'Desktop', 'ClipFloat.lnk')); $sc.TargetPath = '%SCRIPTDIR%FloatingSnip.bat'; $sc.WorkingDirectory = '%SCRIPTDIR%'; $sc.Description = 'Launch ClipFloat'; $sc.Save()"
echo        Done.

:: Launch ClipFloat
echo  [3/3] Launching ClipFloat...
start "" "%SCRIPTDIR%FloatingSnip.bat"
echo        Done.

echo.
echo  ===============================
echo   Install complete!
echo  ===============================
echo.
echo   ClipFloat is now running.
echo   Look for the teal bubble in
echo   the top-right of your screen.
echo.
echo   HOW TO USE:
echo     1. Win+Shift+S to snip
echo        (or Ctrl+C on any image file)
echo     2. Click the bubble
echo     3. Ctrl+V to paste the path
echo.
echo   It will start automatically
echo   when you log in.
echo.
pause
