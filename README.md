# ClipFloat

A tiny floating always-on-top bubble for Windows that bridges your clipboard to [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI.

Take a screen snip or copy an image file, click the bubble, and paste the path straight into Claude Code. No more saving files manually and hunting for paths.

## How It Works

1. **Win+Shift+S** to snip your screen (or **Ctrl+C** on any image file in Explorer)
2. **Click the floating bubble**
3. **Ctrl+V** into Claude Code

The bubble flashes green on success, red if nothing valid is on the clipboard. It never crashes — errors are caught silently.

## Features

- **Screen snips** — captures clipboard image data and saves as PNG
- **Image files** — detects copied image files (PNG, JPG, GIF, BMP, WEBP, TIFF, SVG, ICO) from Explorer
- **Always-on-top** floating bubble with custom-drawn viewfinder icon
- **Draggable** — move it anywhere on screen
- **Hover effect** — subtle opacity change on mouseover
- **Visual feedback** — green checkmark on success, red X on error
- **Right-click to close**

## Supported Image Formats

PNG, JPG, JPEG, GIF, BMP, WEBP, TIFF, TIF, ICO, SVG

## Installation

1. Clone this repo to `C:\Users\<YourName>\ClaudeSnips\` (or wherever you like)
2. Run `FloatingSnip.bat` to launch the bubble
3. Optionally place a shortcut in your Windows Startup folder for auto-launch

## Files

| File | Description |
|------|-------------|
| `FloatingSnip.ps1` | Main floating bubble application |
| `FloatingSnip.bat` | Launcher (bypasses execution policy) |
| `PasteSnip.ps1` | Standalone CLI version (no bubble) |
| `PasteSnip.bat` | Launcher for CLI version |
| `RestartSnip.ps1` | Helper to kill and restart the bubble |
| `CreateShortcut.ps1` | Creates a desktop shortcut |

## Requirements

- Windows 10/11
- PowerShell 5.1+
- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)

## License

MIT
