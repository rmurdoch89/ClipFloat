Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- P/Invoke for global hotkey ---
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class HotKeyHelper {
    [DllImport("user32.dll")] public static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, uint vk);
    [DllImport("user32.dll")] public static extern bool UnregisterHotKey(IntPtr hWnd, int id);
    public const int WM_HOTKEY = 0x0312;
    public const uint MOD_CTRL = 0x0002;
    public const uint MOD_SHIFT = 0x0004;
    public const uint VK_V = 0x56;
}
"@

# =========================================================
#  CONFIG
# =========================================================
$appFolder = [System.IO.Path]::Combine($env:USERPROFILE, "ClaudeSnips")
$settingsFile = [System.IO.Path]::Combine($appFolder, "clipfloat.json")
$maxHistoryItems = 10
$autoCleanupDays = 7
$imageExts = @('.png','.jpg','.jpeg','.gif','.bmp','.webp','.tiff','.tif','.ico','.svg')

if (-not (Test-Path $appFolder)) {
    New-Item -ItemType Directory -Path $appFolder -Force | Out-Null
}

# =========================================================
#  SETTINGS (position memory + preferences)
# =========================================================
# Modifier constants
$MOD_ALT = 0x0001; $MOD_CTRL = 0x0002; $MOD_SHIFT = 0x0004; $MOD_WIN = 0x0008

$script:settings = @{ X = -1; Y = -1; AutoPaste = $false; HotkeyMods = 6; HotkeyKey = 0x56; SnipsFolder = "" }
# Default: Ctrl(2)+Shift(4)=6, V=0x56

function Load-Settings {
    if (Test-Path $settingsFile) {
        try {
            $json = Get-Content $settingsFile -Raw | ConvertFrom-Json
            if ($null -ne $json.X) { $script:settings.X = $json.X }
            if ($null -ne $json.Y) { $script:settings.Y = $json.Y }
            if ($null -ne $json.AutoPaste) { $script:settings.AutoPaste = $json.AutoPaste }
            if ($null -ne $json.HotkeyMods) { $script:settings.HotkeyMods = $json.HotkeyMods }
            if ($null -ne $json.HotkeyKey) { $script:settings.HotkeyKey = $json.HotkeyKey }
            if ($null -ne $json.SnipsFolder -and $json.SnipsFolder -ne "") { $script:settings.SnipsFolder = $json.SnipsFolder }
        } catch {}
    }
}

function Get-SnipsFolder {
    if ($script:settings.SnipsFolder -ne "" -and (Test-Path $script:settings.SnipsFolder)) {
        return $script:settings.SnipsFolder
    }
    return $appFolder
}

function Set-SnipsFolder {
    $browser = New-Object System.Windows.Forms.FolderBrowserDialog
    $browser.Description = "Choose where to save snips"
    $browser.SelectedPath = Get-SnipsFolder
    $browser.ShowNewFolderButton = $true
    if ($browser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $script:settings.SnipsFolder = $browser.SelectedPath
        Save-Settings
        $notifyIcon.BalloonTipTitle = "ClipFloat"
        $notifyIcon.BalloonTipText = "Snips folder: $($browser.SelectedPath)"
        $notifyIcon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
        $notifyIcon.ShowBalloonTip(2000)
    }
    $browser.Dispose()
}

function Get-HotkeyDisplayText {
    $parts = @()
    $mods = $script:settings.HotkeyMods
    if ($mods -band $MOD_CTRL)  { $parts += "Ctrl" }
    if ($mods -band $MOD_ALT)   { $parts += "Alt" }
    if ($mods -band $MOD_SHIFT) { $parts += "Shift" }
    if ($mods -band $MOD_WIN)   { $parts += "Win" }
    $keyName = [System.Windows.Forms.Keys]$script:settings.HotkeyKey
    $parts += $keyName.ToString()
    return ($parts -join "+")
}

function Register-GlobalHotkey {
    [HotKeyHelper]::UnregisterHotKey($form.Handle, $hotkeyId) | Out-Null
    [HotKeyHelper]::RegisterHotKey(
        $form.Handle, $hotkeyId,
        [uint32]$script:settings.HotkeyMods,
        [uint32]$script:settings.HotkeyKey
    ) | Out-Null
}

function Show-HotkeyPicker {
    $picker = New-Object System.Windows.Forms.Form
    $picker.Text = "Set Hotkey"
    $picker.Size = New-Object System.Drawing.Size(340, 200)
    $picker.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $picker.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $picker.MaximizeBox = $false
    $picker.MinimizeBox = $false
    $picker.TopMost = $true
    $picker.BackColor = [System.Drawing.Color]::FromArgb(35, 35, 38)
    $picker.ForeColor = [System.Drawing.Color]::White
    $picker.Font = New-Object System.Drawing.Font("Segoe UI", 10)

    $label = New-Object System.Windows.Forms.Label
    $label.Text = "Press your desired hotkey combination:"
    $label.Location = New-Object System.Drawing.Point(20, 20)
    $label.Size = New-Object System.Drawing.Size(300, 25)
    $label.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 200)
    $picker.Controls.Add($label)

    $hotkeyBox = New-Object System.Windows.Forms.TextBox
    $hotkeyBox.Location = New-Object System.Drawing.Point(20, 55)
    $hotkeyBox.Size = New-Object System.Drawing.Size(290, 35)
    $hotkeyBox.Font = New-Object System.Drawing.Font("Segoe UI", 14)
    $hotkeyBox.BackColor = [System.Drawing.Color]::FromArgb(55, 55, 58)
    $hotkeyBox.ForeColor = [System.Drawing.Color]::White
    $hotkeyBox.TextAlign = [System.Windows.Forms.HorizontalAlignment]::Center
    $hotkeyBox.ReadOnly = $true
    $hotkeyBox.Text = Get-HotkeyDisplayText
    $hotkeyBox.Cursor = [System.Windows.Forms.Cursors]::Arrow
    $picker.Controls.Add($hotkeyBox)

    $script:pickedMods = $script:settings.HotkeyMods
    $script:pickedKey = $script:settings.HotkeyKey
    $script:pickedValid = $false

    $hotkeyBox.Add_KeyDown({
        param($sender, $e)
        $e.SuppressKeyPress = $true
        $e.Handled = $true

        $mods = 0
        if ($e.Control) { $mods = $mods -bor $MOD_CTRL }
        if ($e.Alt)     { $mods = $mods -bor $MOD_ALT }
        if ($e.Shift)   { $mods = $mods -bor $MOD_SHIFT }

        $key = $e.KeyCode
        # Ignore standalone modifier keys
        if ($key -eq [System.Windows.Forms.Keys]::ControlKey -or
            $key -eq [System.Windows.Forms.Keys]::ShiftKey -or
            $key -eq [System.Windows.Forms.Keys]::Menu -or
            $key -eq [System.Windows.Forms.Keys]::LMenu -or
            $key -eq [System.Windows.Forms.Keys]::RMenu) {
            # Show partial combo while holding modifiers
            $parts = @()
            if ($mods -band $MOD_CTRL)  { $parts += "Ctrl" }
            if ($mods -band $MOD_ALT)   { $parts += "Alt" }
            if ($mods -band $MOD_SHIFT) { $parts += "Shift" }
            $parts += "..."
            $hotkeyBox.Text = ($parts -join "+")
            return
        }

        if ($mods -eq 0) {
            $hotkeyBox.Text = "(need Ctrl, Alt, or Shift + a key)"
            $script:pickedValid = $false
            return
        }

        $script:pickedMods = $mods
        $script:pickedKey = [int]$key
        $script:pickedValid = $true

        $parts = @()
        if ($mods -band $MOD_CTRL)  { $parts += "Ctrl" }
        if ($mods -band $MOD_ALT)   { $parts += "Alt" }
        if ($mods -band $MOD_SHIFT) { $parts += "Shift" }
        $parts += $key.ToString()
        $hotkeyBox.Text = ($parts -join "+")
    })

    $btnSave = New-Object System.Windows.Forms.Button
    $btnSave.Text = "Save"
    $btnSave.Location = New-Object System.Drawing.Point(110, 110)
    $btnSave.Size = New-Object System.Drawing.Size(100, 35)
    $btnSave.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnSave.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $btnSave.ForeColor = [System.Drawing.Color]::White
    $btnSave.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btnSave.FlatAppearance.BorderSize = 0
    $btnSave.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnSave.Add_Click({
        if ($script:pickedValid) {
            $script:settings.HotkeyMods = $script:pickedMods
            $script:settings.HotkeyKey = $script:pickedKey
            Save-Settings
            Register-GlobalHotkey
            $notifyIcon.BalloonTipTitle = "ClipFloat"
            $notifyIcon.BalloonTipText = "Hotkey changed to $(Get-HotkeyDisplayText)"
            $notifyIcon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
            $notifyIcon.ShowBalloonTip(2000)
        }
        $picker.Close()
    })
    $picker.Controls.Add($btnSave)

    $picker.Add_Shown({ $hotkeyBox.Focus() })
    $picker.ShowDialog()
    $picker.Dispose()
}

function Save-Settings {
    try {
        $script:settings | ConvertTo-Json | Set-Content $settingsFile -Force
    } catch {}
}

Load-Settings

# =========================================================
#  AUTO-CLEANUP: delete snips older than N days
# =========================================================
try {
    $cutoff = (Get-Date).AddDays(-$autoCleanupDays)
    Get-ChildItem ([System.IO.Path]::Combine((Get-SnipsFolder), "snip_*.png")) -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt $cutoff } |
        Remove-Item -Force -ErrorAction SilentlyContinue
} catch {}

# =========================================================
#  FORM SETUP
# =========================================================
$size = 56

# Load orb image
$script:orbImage = $null
$orbPath = [System.IO.Path]::Combine($PSScriptRoot, "orb.png")
if (-not (Test-Path $orbPath)) {
    $orbPath = [System.IO.Path]::Combine($appFolder, "orb.png")
}
if (Test-Path $orbPath) {
    $script:orbImage = New-Object System.Drawing.Bitmap($orbPath)
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "ClipFloat"
$form.Size = New-Object System.Drawing.Size($size, $size)
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
$form.TopMost = $true
$form.ShowInTaskbar = $false
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::Manual
$form.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
$form.TransparencyKey = [System.Drawing.Color]::FromArgb(1, 1, 1)
$form.BackColor = [System.Drawing.Color]::FromArgb(1, 1, 1)
$form.Opacity = 0.95
$form.AllowDrop = $true

$form.GetType().GetProperty("DoubleBuffered",
    [System.Reflection.BindingFlags]"Instance,NonPublic").SetValue($form, $true)

# Position: restore saved or default top-right
$screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
if ($script:settings.X -ge 0 -and $script:settings.Y -ge 0) {
    $form.Location = New-Object System.Drawing.Point($script:settings.X, $script:settings.Y)
} else {
    $form.Location = New-Object System.Drawing.Point(($screen.Right - 76), 20)
}

# =========================================================
#  SYSTEM TRAY ICON (for notifications)
# =========================================================
$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Text = "ClipFloat"
$notifyIcon.Visible = $true

# Create tray icon from orb image or fallback to teal circle
$iconBmp = New-Object System.Drawing.Bitmap(16, 16)
$iconG = [System.Drawing.Graphics]::FromImage($iconBmp)
$iconG.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$iconG.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$iconG.Clear([System.Drawing.Color]::Transparent)
if ($null -ne $script:orbImage) {
    $iconG.DrawImage($script:orbImage, 0, 0, 16, 16)
} else {
    $iconBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(0, 150, 136))
    $iconG.FillEllipse($iconBrush, 1, 1, 14, 14)
    $iconBrush.Dispose()
}
$iconG.Dispose()
$notifyIcon.Icon = [System.Drawing.Icon]::FromHandle($iconBmp.GetHicon())

# --- Tray icon context menu ---
$trayMenu = New-Object System.Windows.Forms.ContextMenuStrip
$trayMenu.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
$trayMenu.ForeColor = [System.Drawing.Color]::White
$trayMenu.ShowImageMargin = $false
$trayMenu.Font = New-Object System.Drawing.Font("Segoe UI", 9)

$trayShowItem = New-Object System.Windows.Forms.ToolStripMenuItem("Hide Bubble")
$trayShowItem.ForeColor = [System.Drawing.Color]::White
$trayShowItem.Add_Click({
    if ($script:bubbleVisible) {
        $form.Hide()
        $script:bubbleVisible = $false
        $trayShowItem.Text = "Show Bubble"
    } else {
        $form.Show()
        $form.TopMost = $true
        $script:bubbleVisible = $true
        $trayShowItem.Text = "Hide Bubble"
    }
})
$trayMenu.Items.Add($trayShowItem) | Out-Null

$trayCaptureItem = New-Object System.Windows.Forms.ToolStripMenuItem("Capture Clipboard")
$trayCaptureItem.ForeColor = [System.Drawing.Color]::White
$trayCaptureItem.Add_Click({ Invoke-Capture })
$trayMenu.Items.Add($trayCaptureItem) | Out-Null

$trayMenu.Items.Add("-") | Out-Null

$trayOpenItem = New-Object System.Windows.Forms.ToolStripMenuItem("Open Snips Folder")
$trayOpenItem.ForeColor = [System.Drawing.Color]::White
$trayOpenItem.Add_Click({ Start-Process "explorer.exe" (Get-SnipsFolder) })
$trayMenu.Items.Add($trayOpenItem) | Out-Null

$trayMenu.Items.Add("-") | Out-Null

$trayQuitItem = New-Object System.Windows.Forms.ToolStripMenuItem("Quit ClipFloat")
$trayQuitItem.ForeColor = [System.Drawing.Color]::FromArgb(220, 100, 100)
$trayQuitItem.Add_Click({
    $script:reallyClosing = $true
    $form.Close()
})
$trayMenu.Items.Add($trayQuitItem) | Out-Null

$notifyIcon.ContextMenuStrip = $trayMenu

# Double-click tray icon to toggle bubble
$notifyIcon.Add_DoubleClick({
    if ($script:bubbleVisible) {
        $form.Hide()
        $script:bubbleVisible = $false
        $trayShowItem.Text = "Show Bubble"
    } else {
        $form.Show()
        $form.TopMost = $true
        $script:bubbleVisible = $true
        $trayShowItem.Text = "Hide Bubble"
    }
})

# =========================================================
#  STATE
# =========================================================
$script:dragging = $false
$script:dragStart = New-Object System.Drawing.Point(0, 0)
$script:iconMode = "default"
$script:autoPasteEnabled = $script:settings.AutoPaste
$script:lastClipHash = ""
$script:reallyClosing = $false
$script:bubbleVisible = $true

# =========================================================
#  TOOLTIP
# =========================================================
$tooltip = New-Object System.Windows.Forms.ToolTip
$tooltip.InitialDelay = 400
$tooltip.SetToolTip($form, "ClipFloat`nClick: Capture  |  Right-click: Menu`nCtrl+Shift+V: Global hotkey`nDrag to move")

# =========================================================
#  CORE: process clipboard and return file path or $null
# =========================================================
function Get-ClipboardImagePath {
    $filePath = $null

    # Check 1: Copied file from Explorer
    try {
        $files = [System.Windows.Forms.Clipboard]::GetFileDropList()
        if ($null -ne $files -and $files.Count -gt 0) {
            foreach ($f in $files) {
                $ext = [System.IO.Path]::GetExtension($f).ToLower()
                if ($imageExts -contains $ext) {
                    $filePath = $f
                    break
                }
            }
        }
    } catch {}

    # Check 2: Screenshot image data
    if ($null -eq $filePath) {
        try {
            $img = [System.Windows.Forms.Clipboard]::GetImage()
            if ($null -ne $img) {
                $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
                $filePath = [System.IO.Path]::Combine((Get-SnipsFolder), "snip_$timestamp.png")
                $img.Save($filePath, [System.Drawing.Imaging.ImageFormat]::Png)
                $img.Dispose()
            }
        } catch {}
    }

    # Check 3: Text path to image
    if ($null -eq $filePath) {
        try {
            $text = [System.Windows.Forms.Clipboard]::GetText()
            if ($text -and (Test-Path $text)) {
                $ext = [System.IO.Path]::GetExtension($text).ToLower()
                if ($imageExts -contains $ext) {
                    $filePath = $text
                }
            }
        } catch {}
    }

    return $filePath
}

# =========================================================
#  CORE: handle a capture action (from click, hotkey, auto, or drop)
# =========================================================
function Invoke-Capture {
    param([string]$OverridePath)

    $filePath = $null

    if ($OverridePath) {
        $filePath = $OverridePath
    } else {
        $filePath = Get-ClipboardImagePath
    }

    if ($null -eq $filePath) {
        $script:iconMode = "error"
        $form.Invalidate()
        $flashTimer.Start()
        return
    }

    [System.Windows.Forms.Clipboard]::SetText($filePath)

    $script:iconMode = "success"
    $form.Invalidate()
    $flashTimer.Start()

    # Notification toast
    $fileName = [System.IO.Path]::GetFileName($filePath)
    $notifyIcon.BalloonTipTitle = "ClipFloat"
    $notifyIcon.BalloonTipText = "Path copied: $fileName"
    $notifyIcon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
    $notifyIcon.ShowBalloonTip(2000)
}

# =========================================================
#  HISTORY: get recent snips
# =========================================================
function Get-RecentSnips {
    $allSnips = @()

    # Get saved snips
    $snipFiles = Get-ChildItem ([System.IO.Path]::Combine((Get-SnipsFolder), "snip_*.png")) -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First $maxHistoryItems

    foreach ($f in $snipFiles) {
        $allSnips += $f.FullName
    }

    return $allSnips
}

# =========================================================
#  CONTEXT MENU
# =========================================================
$contextMenu = New-Object System.Windows.Forms.ContextMenuStrip
$contextMenu.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
$contextMenu.ForeColor = [System.Drawing.Color]::White
$contextMenu.ShowImageMargin = $false
$contextMenu.Font = New-Object System.Drawing.Font("Segoe UI", 9)

# Custom renderer for clean dark menu
Add-Type @"
using System;
using System.Drawing;
using System.Windows.Forms;
public class DarkMenuRenderer : ToolStripProfessionalRenderer {
    protected override void OnRenderMenuItemBackground(ToolStripItemRenderEventArgs e) {
        Rectangle rc = new Rectangle(Point.Empty, e.Item.Size);
        Color c = e.Item.Selected ? Color.FromArgb(65, 65, 68) : Color.FromArgb(45, 45, 48);
        using (SolidBrush brush = new SolidBrush(c)) {
            e.Graphics.FillRectangle(brush, rc);
        }
    }
    protected override void OnRenderSeparator(ToolStripSeparatorRenderEventArgs e) {
        int y = e.Item.Height / 2;
        using (Pen pen = new Pen(Color.FromArgb(70, 70, 73))) {
            e.Graphics.DrawLine(pen, 4, y, e.Item.Width - 4, y);
        }
    }
    protected override void OnRenderToolStripBackground(ToolStripRenderEventArgs e) {
        using (SolidBrush brush = new SolidBrush(Color.FromArgb(45, 45, 48))) {
            e.Graphics.FillRectangle(brush, e.AffectedBounds);
        }
    }
    protected override void OnRenderToolStripBorder(ToolStripRenderEventArgs e) {
        using (Pen pen = new Pen(Color.FromArgb(70, 70, 73))) {
            Rectangle r = new Rectangle(0, 0, e.AffectedBounds.Width - 1, e.AffectedBounds.Height - 1);
            e.Graphics.DrawRectangle(pen, r);
        }
    }
}
"@ -ReferencedAssemblies System.Drawing, System.Windows.Forms

$contextMenu.Renderer = New-Object DarkMenuRenderer
$trayMenu.Renderer = New-Object DarkMenuRenderer

function Build-ContextMenu {
    $contextMenu.Items.Clear()

    # --- History submenu ---
    $historyItem = New-Object System.Windows.Forms.ToolStripMenuItem("Recent Snips")
    $historyItem.ForeColor = [System.Drawing.Color]::White

    $recentSnips = Get-RecentSnips
    if ($recentSnips.Count -eq 0) {
        $emptyItem = New-Object System.Windows.Forms.ToolStripMenuItem("(none)")
        $emptyItem.Enabled = $false
        $emptyItem.ForeColor = [System.Drawing.Color]::Gray
        $historyItem.DropDown.Renderer = New-Object DarkMenuRenderer
        $historyItem.DropDown.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
        $historyItem.DropDownItems.Add($emptyItem) | Out-Null
    } else {
        $historyItem.DropDown.Renderer = New-Object DarkMenuRenderer
        $historyItem.DropDown.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
        foreach ($snip in $recentSnips) {
            $fileName = [System.IO.Path]::GetFileName($snip)
            $snipItem = New-Object System.Windows.Forms.ToolStripMenuItem($fileName)
            $snipItem.ForeColor = [System.Drawing.Color]::White
            $snipItem.Tag = $snip
            $snipItem.Add_Click({
                param($s, $ev)
                $path = $s.Tag
                [System.Windows.Forms.Clipboard]::SetText($path)
                $notifyIcon.BalloonTipTitle = "ClipFloat"
                $notifyIcon.BalloonTipText = "Path copied: $([System.IO.Path]::GetFileName($path))"
                $notifyIcon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
                $notifyIcon.ShowBalloonTip(2000)
            })
            $historyItem.DropDownItems.Add($snipItem) | Out-Null
        }
    }
    $contextMenu.Items.Add($historyItem) | Out-Null

    $contextMenu.Items.Add("-") | Out-Null

    # --- Auto-paste toggle ---
    $autoLabel = if ($script:autoPasteEnabled) { "Auto-Paste: ON" } else { "Auto-Paste: OFF" }
    $autoItem = New-Object System.Windows.Forms.ToolStripMenuItem($autoLabel)
    $autoItem.ForeColor = if ($script:autoPasteEnabled) {
        [System.Drawing.Color]::FromArgb(100, 220, 100)
    } else {
        [System.Drawing.Color]::White
    }
    $autoItem.Add_Click({
        $script:autoPasteEnabled = -not $script:autoPasteEnabled
        $script:settings.AutoPaste = $script:autoPasteEnabled
        Save-Settings
        if ($script:autoPasteEnabled) {
            $script:lastClipHash = ""
            $autoTimer.Start()
            $notifyIcon.BalloonTipTitle = "ClipFloat"
            $notifyIcon.BalloonTipText = "Auto-paste enabled"
            $notifyIcon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
            $notifyIcon.ShowBalloonTip(1500)
        } else {
            $autoTimer.Stop()
            $notifyIcon.BalloonTipTitle = "ClipFloat"
            $notifyIcon.BalloonTipText = "Auto-paste disabled"
            $notifyIcon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
            $notifyIcon.ShowBalloonTip(1500)
        }
    })
    $contextMenu.Items.Add($autoItem) | Out-Null

    $contextMenu.Items.Add("-") | Out-Null

    # --- Open folder ---
    $snipsFolderPath = Get-SnipsFolder
    $openItem = New-Object System.Windows.Forms.ToolStripMenuItem("Open Snips Folder")
    $openItem.ForeColor = [System.Drawing.Color]::White
    $openItem.Add_Click({ Start-Process "explorer.exe" (Get-SnipsFolder) })
    $contextMenu.Items.Add($openItem) | Out-Null

    # --- Change snips folder ---
    $changeFolderItem = New-Object System.Windows.Forms.ToolStripMenuItem("Change Snips Folder...")
    $changeFolderItem.ForeColor = [System.Drawing.Color]::FromArgb(180, 180, 180)
    $changeFolderItem.Add_Click({ Set-SnipsFolder })
    $contextMenu.Items.Add($changeFolderItem) | Out-Null

    # --- Clear snips ---
    $clearItem = New-Object System.Windows.Forms.ToolStripMenuItem("Clear All Snips")
    $clearItem.ForeColor = [System.Drawing.Color]::White
    $clearItem.Add_Click({
        $snips = Get-ChildItem ([System.IO.Path]::Combine((Get-SnipsFolder), "snip_*.png")) -ErrorAction SilentlyContinue
        $count = ($snips | Measure-Object).Count
        if ($count -gt 0) {
            $result = [System.Windows.Forms.MessageBox]::Show(
                "Delete $count saved snip(s)?", "ClipFloat",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Question)
            if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                $snips | Remove-Item -Force
            }
        }
    })
    $contextMenu.Items.Add($clearItem) | Out-Null

    $contextMenu.Items.Add("-") | Out-Null

    # --- Change hotkey ---
    $hotkeyDisplay = Get-HotkeyDisplayText
    $hotkeyItem = New-Object System.Windows.Forms.ToolStripMenuItem("Hotkey: $hotkeyDisplay  (click to change)")
    $hotkeyItem.ForeColor = [System.Drawing.Color]::FromArgb(180, 180, 180)
    $hotkeyItem.Add_Click({ Show-HotkeyPicker })
    $contextMenu.Items.Add($hotkeyItem) | Out-Null

    $contextMenu.Items.Add("-") | Out-Null

    # --- Hide bubble ---
    $hideItem = New-Object System.Windows.Forms.ToolStripMenuItem("Hide Bubble")
    $hideItem.ForeColor = [System.Drawing.Color]::White
    $hideItem.Add_Click({
        $form.Hide()
        $script:bubbleVisible = $false
        $trayShowItem.Text = "Show Bubble"
        $notifyIcon.BalloonTipTitle = "ClipFloat"
        $notifyIcon.BalloonTipText = "Running in system tray. Double-click tray icon to show."
        $notifyIcon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
        $notifyIcon.ShowBalloonTip(2000)
    })
    $contextMenu.Items.Add($hideItem) | Out-Null

    # --- Quit ---
    $quitItem = New-Object System.Windows.Forms.ToolStripMenuItem("Quit ClipFloat")
    $quitItem.ForeColor = [System.Drawing.Color]::FromArgb(220, 100, 100)
    $quitItem.Add_Click({
        $script:reallyClosing = $true
        $form.Close()
    })
    $contextMenu.Items.Add($quitItem) | Out-Null
}

# =========================================================
#  PAINT: orb image with status overlays
# =========================================================
$form.Add_Paint({
    param($sender, $e)
    $g = $e.Graphics
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

    # Draw the orb image
    if ($null -ne $script:orbImage) {
        $g.DrawImage($script:orbImage, 0, 0, $size, $size)
    } else {
        # Fallback: draw teal circle
        $fallbackBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(0, 150, 136))
        $g.FillEllipse($fallbackBrush, 2, 2, ($size - 4), ($size - 4))
        $fallbackBrush.Dispose()
    }

    # Status overlays
    if ($script:iconMode -eq "success") {
        # Semi-transparent green overlay
        $overlayBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(140, 50, 200, 50))
        $g.FillEllipse($overlayBrush, 3, 3, ($size - 6), ($size - 6))
        $overlayBrush.Dispose()
        # White checkmark
        $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::White, 3.5)
        $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
        $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
        $cx = $size / 2; $cy = $size / 2
        $g.DrawLine($pen, ($cx - 10), $cy, ($cx - 3), ($cy + 8))
        $g.DrawLine($pen, ($cx - 3), ($cy + 8), ($cx + 12), ($cy - 8))
        $pen.Dispose()
    }
    elseif ($script:iconMode -eq "error") {
        # Semi-transparent red overlay
        $overlayBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(140, 200, 50, 50))
        $g.FillEllipse($overlayBrush, 3, 3, ($size - 6), ($size - 6))
        $overlayBrush.Dispose()
        # White X
        $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::White, 3.5)
        $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
        $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
        $cx = $size / 2; $cy = $size / 2
        $g.DrawLine($pen, ($cx - 9), ($cy - 9), ($cx + 9), ($cy + 9))
        $g.DrawLine($pen, ($cx + 9), ($cy - 9), ($cx - 9), ($cy + 9))
        $pen.Dispose()
    }

    # Auto-paste indicator dot (bottom-right)
    if ($script:autoPasteEnabled) {
        $dotBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(100, 220, 100))
        $g.FillEllipse($dotBrush, ($size - 16), ($size - 16), 10, 10)
        $dotBorder = New-Object System.Drawing.Pen([System.Drawing.Color]::White, 1.5)
        $g.DrawEllipse($dotBorder, ($size - 16), ($size - 16), 10, 10)
        $dotBrush.Dispose()
        $dotBorder.Dispose()
    }
})

# =========================================================
#  HOVER EFFECT
# =========================================================
$form.Add_MouseEnter({ $form.Opacity = 1.0 })
$form.Add_MouseLeave({ $form.Opacity = 0.92 })

# =========================================================
#  DRAG TO MOVE (with position save)
# =========================================================
$form.Add_MouseDown({
    $script:dragging = $true
    $script:dragStart = New-Object System.Drawing.Point($_.X, $_.Y)
})
$form.Add_MouseMove({
    if ($script:dragging) {
        $form.Location = New-Object System.Drawing.Point(
            ($form.Left + $_.X - $script:dragStart.X),
            ($form.Top + $_.Y - $script:dragStart.Y)
        )
    }
})
$form.Add_MouseUp({
    if ($script:dragging) {
        $script:dragging = $false
        $script:settings.X = $form.Left
        $script:settings.Y = $form.Top
        Save-Settings
    }
})

# =========================================================
#  DRAG & DROP: drop image files onto the bubble
# =========================================================
$form.Add_DragEnter({
    param($sender, $e)
    if ($e.Data.GetDataPresent([System.Windows.Forms.DataFormats]::FileDrop)) {
        $files = $e.Data.GetData([System.Windows.Forms.DataFormats]::FileDrop)
        foreach ($f in $files) {
            $ext = [System.IO.Path]::GetExtension($f).ToLower()
            if ($imageExts -contains $ext) {
                $e.Effect = [System.Windows.Forms.DragDropEffects]::Copy
                return
            }
        }
    }
    $e.Effect = [System.Windows.Forms.DragDropEffects]::None
})

$form.Add_DragLeave({
    $form.Invalidate()
})

$form.Add_DragDrop({
    param($sender, $e)
    try {
        $files = $e.Data.GetData([System.Windows.Forms.DataFormats]::FileDrop)
        foreach ($f in $files) {
            $ext = [System.IO.Path]::GetExtension($f).ToLower()
            if ($imageExts -contains $ext) {
                Invoke-Capture -OverridePath $f
                return
            }
        }
    } catch {
        $script:iconMode = "error"
        $form.Invalidate()
        $flashTimer.Start()
    }
})

# =========================================================
#  TIMERS
# =========================================================

# Flash timer (reset icon after feedback)
$flashTimer = New-Object System.Windows.Forms.Timer
$flashTimer.Interval = 800
$flashTimer.Add_Tick({
    $flashTimer.Stop()
    $script:iconMode = "default"
    $form.Invalidate()
})

# Auto-paste timer (watches clipboard for new images)
$autoTimer = New-Object System.Windows.Forms.Timer
$autoTimer.Interval = 1500

$autoTimer.Add_Tick({
    if (-not $script:autoPasteEnabled) { return }
    try {
        $hasImage = [System.Windows.Forms.Clipboard]::ContainsImage()
        $hasFiles = [System.Windows.Forms.Clipboard]::ContainsFileDropList()

        if (-not $hasImage -and -not $hasFiles) { return }

        # Build a hash to detect change
        $hash = ""
        if ($hasImage) {
            try {
                $img = [System.Windows.Forms.Clipboard]::GetImage()
                if ($null -ne $img) {
                    $hash = "img_" + $img.Width + "x" + $img.Height + "_" + $img.GetHashCode()
                    $img.Dispose()
                }
            } catch {}
        }
        if ($hasFiles -and $hash -eq "") {
            try {
                $files = [System.Windows.Forms.Clipboard]::GetFileDropList()
                if ($null -ne $files -and $files.Count -gt 0) {
                    $hash = "file_" + ($files -join "|")
                }
            } catch {}
        }

        if ($hash -ne "" -and $hash -ne $script:lastClipHash) {
            $script:lastClipHash = $hash
            Invoke-Capture
        }
    } catch {}
})

if ($script:autoPasteEnabled) { $autoTimer.Start() }

# =========================================================
#  CLICK HANDLER
# =========================================================
$form.Add_MouseClick({
    param($sender, $e)
    try {
        if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Right) {
            Build-ContextMenu
            $contextMenu.Show($form, $e.Location)
            return
        }
        Invoke-Capture
    } catch {
        $script:iconMode = "error"
        $form.Invalidate()
        $flashTimer.Start()
    }
})

# =========================================================
#  GLOBAL HOTKEY (configurable)
# =========================================================
$hotkeyId = 9001

$form.Add_HandleCreated({
    Register-GlobalHotkey
})

# Message filter for WM_HOTKEY
Add-Type @"
using System;
using System.Windows.Forms;
public class HotKeyFilter : IMessageFilter {
    public int HotKeyId;
    public event EventHandler HotKeyPressed;
    public bool PreFilterMessage(ref Message m) {
        if (m.Msg == 0x0312 && m.WParam.ToInt32() == HotKeyId) {
            if (HotKeyPressed != null) HotKeyPressed(this, EventArgs.Empty);
            return true;
        }
        return false;
    }
}
"@ -ReferencedAssemblies System.Windows.Forms

$filter = New-Object HotKeyFilter
$filter.HotKeyId = $hotkeyId
$filter.Add_HotKeyPressed({ Invoke-Capture })
[System.Windows.Forms.Application]::AddMessageFilter($filter)

# =========================================================
#  CLOSE BEHAVIOR: minimize to tray unless quitting
# =========================================================
$form.Add_FormClosing({
    param($sender, $e)

    if (-not $script:reallyClosing) {
        # Hide to tray instead of closing
        $e.Cancel = $true
        $form.Hide()
        $script:bubbleVisible = $false
        $trayShowItem.Text = "Show Bubble"
        $notifyIcon.BalloonTipTitle = "ClipFloat"
        $notifyIcon.BalloonTipText = "Running in system tray. Double-click tray icon to show."
        $notifyIcon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
        $notifyIcon.ShowBalloonTip(2000)
        return
    }

    # Actually quitting
    [HotKeyHelper]::UnregisterHotKey($form.Handle, $hotkeyId) | Out-Null
    $notifyIcon.Visible = $false
    $notifyIcon.Dispose()
    $autoTimer.Stop()
    $script:settings.X = $form.Left
    $script:settings.Y = $form.Top
    Save-Settings
})

# =========================================================
#  RUN
# =========================================================
[System.Windows.Forms.Application]::Run($form)
