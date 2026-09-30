# WipeReady main window shell (custom chrome, nav, pages, status bar)
# Layout only. No data collection and no export logic here.
# Borderless window: the title bar, its buttons and the resize grip are
# custom-drawn (WinForms cannot theme the native caption per-app).

function New-AppShell {
    $script:form = New-Object System.Windows.Forms.Form
    $script:form.Text = "WipeReady v$script:Version"
    $script:form.Size = New-Object System.Drawing.Size(940, 640)
    $script:form.MinimumSize = New-Object System.Drawing.Size(940, 640)
    $script:form.StartPosition = 'CenterScreen'
    $script:form.BackColor = $T.Bg
    $script:form.ForeColor = $T.Text
    $script:form.Font = $FontUI
    $script:form.AutoScaleMode = 'Dpi'
    $script:form.FormBorderStyle = 'None'

    $script:Tips = New-Object System.Windows.Forms.ToolTip

    # ---- Custom title bar ----
    $script:titleBar = New-Object System.Windows.Forms.Panel
    $script:titleBar.Size = New-Object System.Drawing.Size(940, 36)
    $script:titleBar.Dock = 'Top'
    $script:titleBar.BackColor = $T.Panel
    $script:form.Controls.Add($script:titleBar)

    # Left flow: app name + version side by side (never overlaps, any DPI).
    $titleFlow = New-Object System.Windows.Forms.FlowLayoutPanel
    $titleFlow.Dock = 'Left'
    $titleFlow.AutoSize = $true
    $titleFlow.AutoSizeMode = 'GrowAndShrink'
    $titleFlow.BackColor = $T.Panel
    $titleFlow.FlowDirection = 'LeftToRight'
    $titleFlow.WrapContents = $false
    $titleFlow.Padding = New-Object System.Windows.Forms.Padding(12, 7, 0, 0)
    $script:titleBar.Controls.Add($titleFlow)

    $lblApp = New-Object System.Windows.Forms.Label
    $lblApp.Text = 'WipeReady'
    $lblApp.Font = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
    $lblApp.ForeColor = $T.Accent
    $lblApp.AutoSize = $true
    $lblApp.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, 0)
    $titleFlow.Controls.Add($lblApp)

    $lblVer = New-Object System.Windows.Forms.Label
    $lblVer.Text = "v$script:Version"
    $lblVer.Font = $FontUI
    $lblVer.ForeColor = $T.Muted
    $lblVer.AutoSize = $true
    $lblVer.Margin = New-Object System.Windows.Forms.Padding(6, 2, 0, 0)
    $titleFlow.Controls.Add($lblVer)

    $script:btnMin = New-TitleButton 'min'
    $script:btnMax = New-TitleButton 'max'
    $script:btnClose = New-TitleButton 'close'
    $script:btnClose.FlatAppearance.MouseOverBackColor = [System.Drawing.ColorTranslator]::FromHtml('#e81123')
    $script:titleBar.Controls.Add($script:btnMin)
    $script:titleBar.Controls.Add($script:btnMax)
    $script:titleBar.Controls.Add($script:btnClose)
    Position-TitleButtons
    $script:btnMin.Add_Click({ $script:form.WindowState = 'Minimized' })
    $script:btnMax.Add_Click({ Toggle-Maximize })
    $script:btnClose.Add_Click({ $script:form.Close() })
    Add-Tip $script:btnMin 'Minimize'
    Add-Tip $script:btnMax 'Maximize / restore'
    Add-Tip $script:btnClose 'Close'

    $script:dragging = $false
    $script:dragOffset = New-Object System.Drawing.Point(0, 0)
    $startDrag = {
        if (([System.Windows.Forms.Control]::MouseButtons -band [System.Windows.Forms.MouseButtons]::Left) -and
            ($script:form.WindowState -ne 'Maximized')) {
            $script:dragging = $true
            $script:dragOffset = $script:form.PointToClient([System.Windows.Forms.Cursor]::Position)
            $script:titleBar.Capture = $true
        }
    }
    $moveDrag = {
        if ($script:dragging) {
            $p = [System.Windows.Forms.Cursor]::Position
            $script:form.Location = New-Object System.Drawing.Point(
                ($p.X - $script:dragOffset.X), ($p.Y - $script:dragOffset.Y))
        }
    }
    $endDrag = { $script:dragging = $false }
    foreach ($c in @($script:titleBar, $lblApp, $lblVer)) {
        $c.Add_MouseDown($startDrag)
        $c.Add_MouseMove($moveDrag)
        $c.Add_MouseUp($endDrag)
        $c.Add_DoubleClick({ Toggle-Maximize })
    }
    $script:form.Add_Resize({ Position-TitleButtons })

    $strip = New-Object System.Windows.Forms.Panel
    $strip.Location = New-Object System.Drawing.Point(0, 36)
    $strip.Size = New-Object System.Drawing.Size(940, 4)
    $strip.Anchor = 'Top, Left, Right'
    $strip.BackColor = $T.Accent
    $script:form.Controls.Add($strip)

    $script:NavTable = New-Object System.Windows.Forms.TableLayoutPanel
    $script:NavTable.Location = New-Object System.Drawing.Point(10, 48)
    $script:NavTable.Size = New-Object System.Drawing.Size(904, 42)
    $script:NavTable.Anchor = 'Top, Left, Right'
    $script:NavTable.BackColor = $T.Bg
    $script:NavTable.ColumnCount = 0
    $script:NavTable.RowCount = 1
    $script:NavTable.RowStyles.Add((New-Object System.Windows.Forms.RowStyle(
        [System.Windows.Forms.SizeType]::Absolute, 42))) | Out-Null
    $script:form.Controls.Add($script:NavTable)

    $script:PagesPanel = New-Object System.Windows.Forms.Panel
    $script:PagesPanel.Location = New-Object System.Drawing.Point(10, 96)
    $script:PagesPanel.Size = New-Object System.Drawing.Size(904, 460)
    $script:PagesPanel.Anchor = 'Top, Bottom, Left, Right'
    $script:PagesPanel.BackColor = $T.Bg
    $script:form.Controls.Add($script:PagesPanel)

    $script:PagePanels = @()
    $script:NavButtons = @()

    $script:status = New-Object System.Windows.Forms.StatusStrip
    $script:status.BackColor = $T.Panel
    $script:status.ForeColor = $T.Text
    $script:status.SizingGrip = $false
    $script:statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
    $script:statusLabel.Text = 'Ready.'
    $script:statusLabel.ForeColor = $T.Text
    $script:status.Items.Add($script:statusLabel) | Out-Null
    $script:statusPath = New-Object System.Windows.Forms.ToolStripStatusLabel
    $script:statusPath.Text = 'Desktop\wipeready'
    $script:statusPath.ForeColor = $T.Muted
    $script:statusPath.Alignment = 'Right'
    $script:status.Items.Add($script:statusPath) | Out-Null
    $script:form.Controls.Add($script:status)

    # ---- Resize grip (bottom-right corner) ----
    $script:grip = New-Object System.Windows.Forms.Panel
    $script:grip.Size = New-Object System.Drawing.Size(22, 22)
    $script:grip.Location = New-Object System.Drawing.Point(918, 596)
    $script:grip.Anchor = 'Bottom, Right'
    $script:grip.BackColor = $T.Panel
    $script:grip.Cursor = [System.Windows.Forms.Cursors]::SizeNWSE
    $script:form.Controls.Add($script:grip)
    $script:grip.BringToFront()
    $gripLbl = New-Object System.Windows.Forms.Label
    $gripLbl.Text = '◢'
    $gripLbl.Dock = 'Fill'
    $gripLbl.TextAlign = 'BottomRight'
    $gripLbl.ForeColor = $T.Muted
    $gripLbl.Font = $FontUI
    $script:grip.Controls.Add($gripLbl)

    $script:resizing = $false
    $script:resizeAnchor = New-Object System.Drawing.Point(0, 0)
    $script:resizeSize = New-Object System.Drawing.Size(0, 0)
    $script:grip.Add_MouseDown({
        if ([System.Windows.Forms.Control]::MouseButtons -band [System.Windows.Forms.MouseButtons]::Left) {
            $script:resizing = $true
            $script:resizeAnchor = [System.Windows.Forms.Cursor]::Position
            $script:resizeSize = $script:form.Size
            $script:grip.Capture = $true
        }
    })
    $script:grip.Add_MouseMove({
        if ($script:resizing) {
            $now = [System.Windows.Forms.Cursor]::Position
            $w = $script:resizeSize.Width + ($now.X - $script:resizeAnchor.X)
            $h = $script:resizeSize.Height + ($now.Y - $script:resizeAnchor.Y)
            if ($w -lt $script:form.MinimumSize.Width) { $w = $script:form.MinimumSize.Width }
            if ($h -lt $script:form.MinimumSize.Height) { $h = $script:form.MinimumSize.Height }
            $script:form.Size = New-Object System.Drawing.Size($w, $h)
        }
    })
    $script:grip.Add_MouseUp({ $script:resizing = $false })

    $script:form.Add_FormClosed({
        foreach ($f in @($FontUI, $FontTitle, $FontSection, $FontMono, $FontBoldUI)) {
            if ($f) { $f.Dispose() }
        }
    })
}

function New-TitleButton([string]$kind) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = ''
    $b.Tag = $kind
    $b.Size = New-Object System.Drawing.Size(48, 36)
    $b.FlatStyle = 'Flat'
    $b.UseVisualStyleBackColor = $false
    $b.BackColor = $T.Panel
    $b.ForeColor = $T.Text
    $b.FlatAppearance.BorderSize = 0
    $b.FlatAppearance.MouseOverBackColor = $T.Hover
    $b.Cursor = [System.Windows.Forms.Cursors]::Hand
    $b.Add_Paint({
        param($sender, $e)
        $g = $e.Graphics
        $g.SmoothingMode = 'AntiAlias'
        $pen = New-Object System.Drawing.Pen($sender.ForeColor, 2)
        $cx = $sender.ClientSize.Width / 2
        $cy = $sender.ClientSize.Height / 2
        switch ($sender.Tag) {
            'min' {
                $g.DrawLine($pen, ($cx - 5), $cy, ($cx + 5), $cy)
            }
            'max' {
                $g.DrawRectangle($pen, ($cx - 5), ($cy - 5), 10, 10)
            }
            'restore' {
                $bg = New-Object System.Drawing.SolidBrush($sender.BackColor)
                $g.DrawRectangle($pen, ($cx - 2), ($cy - 7), 9, 9)
                $g.FillRectangle($bg, ($cx - 6), ($cy - 1), 9, 9)
                $g.DrawRectangle($pen, ($cx - 6), ($cy - 1), 9, 9)
                $bg.Dispose()
            }
            'close' {
                $g.DrawLine($pen, ($cx - 5), ($cy - 5), ($cx + 5), ($cy + 5))
                $g.DrawLine($pen, ($cx + 5), ($cy - 5), ($cx - 5), ($cy + 5))
            }
        }
        $pen.Dispose()
    })
    return $b
}

function Position-TitleButtons {
    $y = 0
    $x = $script:titleBar.ClientSize.Width
    foreach ($b in @($script:btnClose, $script:btnMax, $script:btnMin)) {
        if (-not $b) { continue }
        $x -= $b.Width
        $b.Location = New-Object System.Drawing.Point($x, $y)
    }
}

function Toggle-Maximize {
    if ($script:form.WindowState -eq 'Maximized') {
        $script:form.WindowState = 'Normal'
        $script:form.MaximumSize = New-Object System.Drawing.Size(0, 0)
        $script:btnMax.Tag = 'max'
    } else {
        # Cap at the working area so maximized never covers the taskbar.
        # (MaximizedBounds is missing on some runtimes; MaximumSize works.)
        $wa = [System.Windows.Forms.Screen]::FromControl($script:form).WorkingArea.Size
        $script:form.MaximumSize = New-Object System.Drawing.Size($wa.Width, $wa.Height)
        $script:form.WindowState = 'Maximized'
        $script:btnMax.Tag = 'restore'
    }
    $script:btnMax.Invalidate()
}

function Register-Page([string]$title, $panel) {
    # NOTE: $panel was already parented by its builder (binding requirement).
    $panel.Dock = 'Fill'
    $panel.Visible = $false
    $script:PagePanels += $panel

    $idx = $script:PagePanels.Count - 1

    $script:NavTable.ColumnCount = $script:PagePanels.Count
    $script:NavTable.ColumnStyles.Clear()
    for ($i = 0; $i -lt $script:PagePanels.Count; $i++) {
        [void]$script:NavTable.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle(
            [System.Windows.Forms.SizeType]::Percent, (100 / $script:PagePanels.Count))))
    }

    $b = New-StyledButton $title
    $b.Dock = 'Fill'
    $b.Margin = New-Object System.Windows.Forms.Padding(0, 0, 6, 0)
    $j = $idx
    $b.Add_Click({ Show-Page $j }.GetNewClosure())
    $script:NavTable.Controls.Add($b, $idx, 0)
    $script:NavButtons += $b
}

function Show-Page([int]$index) {
    for ($i = 0; $i -lt $script:PagePanels.Count; $i++) {
        $active = ($i -eq $index)
        $script:PagePanels[$i].Visible = $active
        $btn = $script:NavButtons[$i]
        if ($active) {
            $btn.BackColor = $T.Accent
            $btn.ForeColor = $T.Bg
            $btn.Font = $FontBoldUI
        } else {
            $btn.BackColor = $T.Panel
            $btn.ForeColor = $T.Text
            $btn.Font = $FontUI
        }
    }
}

function Set-Status([string]$msg, [string]$Kind = 'Normal') {
    $script:statusLabel.Text = $msg
    $script:statusLabel.ForeColor = switch ($Kind) {
        'Success' { $T.Success }
        'Warn'    { $T.Warn }
        'Error'   { $T.Error }
        'Busy'    { $T.Accent }
        default   { $T.Text }
    }
    $script:form.Refresh()
}

function Show-App {
    [void]$script:form.ShowDialog()
}
