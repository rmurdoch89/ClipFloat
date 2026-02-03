@echo off
echo.
echo  ===============================
echo   ClipFloat Uninstaller
echo  ===============================
echo.

:: Kill running instance
echo  [1/4] Stopping ClipFloat...
taskkill /f /im ClipFloat.exe >nul 2>&1
echo        Done.

:: Remove from startup
echo  [2/4] Removing from startup...
del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\ClipFloat.lnk" >nul 2>&1
del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\FloatingSnip.bat" >nul 2>&1
echo        Done.

:: Remove desktop shortcuts
echo  [3/4] Removing desktop shortcuts...
del "%USERPROFILE%\Desktop\ClipFloat.lnk" >nul 2>&1
del "%USERPROFILE%\Desktop\PasteSnip.lnk" >nul 2>&1
echo        Done.

:: Ask about saved snips
echo  [4/4] Checking saved snips...
dir /b "%USERPROFILE%\ClaudeSnips\snip_*.png" >nul 2>&1
if %errorlevel%==0 (
    echo.
    set /p DELSNIPS="        Delete saved snips? (y/n): "
    if /i "%DELSNIPS%"=="y" (
        del "%USERPROFILE%\ClaudeSnips\snip_*.png" >nul 2>&1
        echo        Snips deleted.
    ) else (
        echo        Snips kept in %USERPROFILE%\ClaudeSnips
    )
) else (
    echo        No saved snips found.
)

echo.
echo  ===============================
echo   Uninstall complete!
echo  ===============================
echo.
echo   ClipFloat has been removed.
echo   You can delete this folder
echo   to fully remove all files.
echo.
pause
