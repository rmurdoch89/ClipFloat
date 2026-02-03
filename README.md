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

| Action | What happens |
|---|---|
| **Win+Shift+S** then **click bubble** | Saves screenshot, copies path to clipboard |
| **Ctrl+C** on image file then **click bubble** | Copies that file's path to clipboard |
| **Ctrl+Shift+V** (global hotkey) | Same as clicking — works from any app |
| **Drag image file onto bubble** | Copies that file's path to clipboard |
| **Ctrl+V** in Claude Code | Pastes the file path |

## Features

### Visual Feedback

| Bubble | Meaning |
|---|---|
| Teal (default) | Ready |
| Green flash + checkmark | Success — path copied |
| Red flash + X | No image found on clipboard |
| Green dot (bottom-right) | Auto-paste mode is active |

### Global Hotkey

Press **Ctrl+Shift+V** from any application to capture the clipboard image — no need to click the bubble. Works even when the bubble is behind other windows.

### Auto-Paste Mode

Right-click the bubble and toggle **Auto-Paste**. When enabled, ClipFloat watches your clipboard and automatically saves any new screenshot and copies its path — completely hands-free. A small green dot appears on the bubble when active.

### Drag and Drop

Drag any image file from Explorer directly onto the bubble. The file path is copied to your clipboard instantly.

### Recent Snips History

Right-click and hover over **Recent Snips** to see your last 10 screenshots. Click any entry to re-copy its path.

### Auto-Cleanup

Screenshots older than 7 days are automatically deleted on startup, keeping your snips folder tidy.

### Position Memory

Drag the bubble anywhere on screen. Your position is saved and restored across restarts, including multi-monitor setups.

### Notification Toasts

A brief Windows notification confirms each capture with the filename.

### Right-Click Menu

- **Recent Snips** — last 10 captures, click to re-copy path
- **Auto-Paste: ON/OFF** — toggle automatic clipboard monitoring
- **Open Snips Folder** — view saved screenshots in Explorer
- **Clear All Snips** — delete all saved screenshots (with confirmation)
- **Hotkey: Ctrl+Shift+V** — reminder of the global shortcut
- **Close ClipFloat** — close the bubble

## Supported Image Formats

PNG, JPG, JPEG, GIF, BMP, WEBP, TIFF, TIF, ICO, SVG

## Uninstall

Double-click **`Uninstall.bat`** to remove ClipFloat from startup, remove shortcuts, and optionally delete saved snips.

## Requirements

- Windows 10 or 11
- PowerShell 5.1+
- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)

## License

MIT
