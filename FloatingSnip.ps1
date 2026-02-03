Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$size = 50

$form = New-Object System.Windows.Forms.Form
$form.Text = "Snip"
$form.Size = New-Object System.Drawing.Size($size, $size)
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
$form.TopMost = $true
$form.ShowInTaskbar = $false
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::Manual
$form.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
$form.Opacity = 0.92

# Enable double buffering to reduce flicker
$form.GetType().GetProperty("DoubleBuffered",
    [System.Reflection.BindingFlags]"Instance,NonPublic").SetValue($form, $true)

# Position in top-right area of primary screen
$screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$form.Location = New-Object System.Drawing.Point(($screen.Right - 70), 20)

# Make it a smooth circle
$path = New-Object System.Drawing.Drawing2D.GraphicsPath
$path.AddEllipse(0, 0, ($size - 1), ($size - 1))
$form.Region = New-Object System.Drawing.Region($path)

# Tooltip
$tooltip = New-Object System.Windows.Forms.ToolTip
$tooltip.SetToolTip($form, "Click: Save clipboard snip`nRight-click: Close`nDrag to move")

# State tracking
$script:dragging = $false
$script:dragStart = New-Object System.Drawing.Point(0, 0)
$script:hovering = $false
$script:iconMode = "default"  # default, success, error

# Custom paint - draw a clean camera/capture icon
$form.Add_Paint({
    param($sender, $e)
    $g = $e.Graphics
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

    # Draw subtle shadow/rim
    $rimPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(40, 255, 255, 255), 1.5)
    $g.DrawEllipse($rimPen, 1, 1, ($size - 3), ($size - 3))
    $rimPen.Dispose()

    $white = New-Object System.Drawing.Pen([System.Drawing.Color]::White, 2.2)
    $whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)

    if ($script:iconMode -eq "success") {
        # Draw checkmark
        $white.Width = 3
        $g.DrawLine($white, 15, 26, 22, 33)
        $g.DrawLine($white, 22, 33, 35, 18)
    }
    elseif ($script:iconMode -eq "error") {
        # Draw X
        $white.Width = 3
        $g.DrawLine($white, 16, 16, 34, 34)
        $g.DrawLine($white, 34, 16, 16, 34)
    }
    else {
        # Draw a viewfinder/crosshair capture icon
        $cx = $size / 2
        $cy = $size / 2
        $r = 12

        # Outer circle
        $g.DrawEllipse($white, ($cx - $r), ($cy - $r), ($r * 2), ($r * 2))

        # Corner brackets (top-left, top-right, bottom-left, bottom-right)
        $b = 6  # bracket length
        $o = 6  # offset from center
        # Top-left
        $g.DrawLine($white, ($cx - $o - $b), ($cy - $o), ($cx - $o), ($cy - $o))
        $g.DrawLine($white, ($cx - $o), ($cy - $o), ($cx - $o), ($cy - $o - $b))
        # Top-right
        $g.DrawLine($white, ($cx + $o + $b), ($cy - $o), ($cx + $o), ($cy - $o))
        $g.DrawLine($white, ($cx + $o), ($cy - $o), ($cx + $o), ($cy - $o - $b))
        # Bottom-left
        $g.DrawLine($white, ($cx - $o - $b), ($cy + $o), ($cx - $o), ($cy + $o))
        $g.DrawLine($white, ($cx - $o), ($cy + $o), ($cx - $o), ($cy + $o + $b))
        # Bottom-right
        $g.DrawLine($white, ($cx + $o + $b), ($cy + $o), ($cx + $o), ($cy + $o))
        $g.DrawLine($white, ($cx + $o), ($cy + $o), ($cx + $o), ($cy + $o + $b))

        # Center dot
        $g.FillEllipse($whiteBrush, ($cx - 2.5), ($cy - 2.5), 5, 5)
    }

    $white.Dispose()
    $whiteBrush.Dispose()
})

# Hover effect
$form.Add_MouseEnter({
    $script:hovering = $true
    $form.Opacity = 1.0
})
$form.Add_MouseLeave({
    $script:hovering = $false
    $form.Opacity = 0.92
})

# Dragging
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
    $script:dragging = $false
})

# Flash with timer (non-blocking)
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 800
$timer.Add_Tick({
    $timer.Stop()
    $script:iconMode = "default"
    $form.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $form.Invalidate()
})

# Supported image extensions
$imageExts = @('.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp', '.tiff', '.tif', '.ico', '.svg')

# Click handler
$form.Add_MouseClick({
    param($sender, $e)
    try {
        if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Right) {
            $form.Close()
            return
        }

        $filePath = $null

        # Check 1: Did the user copy a file from Explorer?
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

        # Check 2: Did the user take a screenshot (image data on clipboard)?
        if ($null -eq $filePath) {
            try {
                $img = [System.Windows.Forms.Clipboard]::GetImage()
                if ($null -ne $img) {
                    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
                    $filePath = "C:\Users\Rob\ClaudeSnips\snip_$timestamp.png"
                    $img.Save($filePath, [System.Drawing.Imaging.ImageFormat]::Png)
                    $img.Dispose()
                }
            } catch {}
        }

        # Check 3: Clipboard might have a file path as text already
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

        # Nothing useful on clipboard
        if ($null -eq $filePath) {
            $script:iconMode = "error"
            $form.BackColor = [System.Drawing.Color]::FromArgb(200, 50, 50)
            $form.Invalidate()
            $timer.Start()
            return
        }

        [System.Windows.Forms.Clipboard]::SetText($filePath)

        $script:iconMode = "success"
        $form.BackColor = [System.Drawing.Color]::FromArgb(50, 180, 50)
        $form.Invalidate()
        $timer.Start()
    } catch {
        # Catch any unexpected error so the bubble never crashes
        $script:iconMode = "error"
        $form.BackColor = [System.Drawing.Color]::FromArgb(200, 50, 50)
        $form.Invalidate()
        $timer.Start()
    }
})

[System.Windows.Forms.Application]::Run($form)
