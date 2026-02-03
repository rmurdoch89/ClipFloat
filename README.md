# ClipFloat

A tiny floating always-on-top bubble for Windows that bridges your clipboard to [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI.

Take a screen snip or copy an image file, click the bubble, and paste the path straight into Claude Code. No more saving files manually and hunting for paths.

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue) ![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D6) ![License](https://img.shields.io/badge/License-MIT-green)

## Quick Start

1. [Download](https://github.com/rmurdoch89/ClipFloat/archive/refs/heads/master.zip) or clone this repo
2. Double-click **`Install.bat`**
3. Done. Look for the teal bubble in the top-right of your screen.

The installer adds ClipFloat to startup, creates a desktop shortcut, and launches the bubble.

## How to Use

1. **Win+Shift+S** to snip your screen (or **Ctrl+C** on any image file in Explorer)
2. **Click the floating bubble**
3. **Ctrl+V** into Claude Code to paste the file path

### Visual Feedback

| Bubble colour | Meaning |
|---|---|
| Teal (default) | Ready |
| Green flash | Success — path copied to clipboard |
| Red flash | No image found on clipboard |

### Right-Click Menu

- **Open Snips Folder** — view saved screenshots
- **Clear All Snips** — delete all saved screenshots
- **Close ClipFloat** — close the bubble

The bubble is draggable — just click and drag it anywhere on screen.

## Supported Formats

PNG, JPG, JPEG, GIF, BMP, WEBP, TIFF, TIF, ICO, SVG

## Uninstall

Double-click **`Uninstall.bat`** to remove ClipFloat from startup, remove shortcuts, and optionally delete saved snips.

## Requirements

- Windows 10 or 11
- PowerShell 5.1+
- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)

## License

MIT
