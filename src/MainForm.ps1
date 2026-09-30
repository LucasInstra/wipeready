# WipeReady main window shell (header, owner-drawn tabs, status bar)
# Layout only. No data collection and no export logic here.

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

    $header = New-Object System.Windows.Forms.Panel
    $header.Location = New-Object System.Drawing.Point(0, 0)
    $header.Size = New-Object System.Drawing.Size(924, 62)
    $header.Anchor = 'Top, Left, Right'
    $header.BackColor = $T.Panel
    $script:form.Controls.Add($header)

    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = 'WipeReady'
    $lblTitle.Font = $FontTitle
    $lblTitle.ForeColor = $T.Accent
    $lblTitle.AutoSize = $true
    $lblTitle.Location = New-Object System.Drawing.Point(16, 6)
    $header.Controls.Add($lblTitle)

    $lblSub = New-Object System.Windows.Forms.Label
    $lblSub.Text = "Pre-format inventory  •  v$script:Version  •  pick what to keep before wiping"
    $lblSub.Font = $FontUI
    $lblSub.ForeColor = $T.Muted
    $lblSub.AutoSize = $true
    $lblSub.Location = New-Object System.Drawing.Point(18, 36)
    $header.Controls.Add($lblSub)

    $strip = New-Object System.Windows.Forms.Panel
    $strip.Location = New-Object System.Drawing.Point(0, 62)
    $strip.Size = New-Object System.Drawing.Size(924, 4)
    $strip.Anchor = 'Top, Left, Right'
    $strip.BackColor = $T.Accent
    $script:form.Controls.Add($strip)

    $script:tabs = New-Object System.Windows.Forms.TabControl
    $script:tabs.Location = New-Object System.Drawing.Point(10, 74)
    $script:tabs.Size = New-Object System.Drawing.Size(904, 482)
    $script:tabs.Anchor = 'Top, Bottom, Left, Right'
    $script:tabs.DrawMode = 'OwnerDrawFixed'
    $script:tabs.SizeMode = 'Fixed'
    $script:tabs.ItemSize = New-Object System.Drawing.Size(170, 34)
    $script:tabs.Font = $FontUI
    $script:form.Controls.Add($script:tabs)

    $script:tabs.Add_DrawItem({
        param($s, $e)
        $selected = ($e.Index -eq $s.SelectedIndex)
        $bg = if ($selected) { $T.Accent } else { $T.Panel }
        $fg = if ($selected) { $T.Bg } else { $T.Text }
        $brush = New-Object System.Drawing.SolidBrush($bg)
        $e.Graphics.FillRectangle($brush, $e.Bounds)
        $brush.Dispose()
        $flags = [System.Windows.Forms.TextFormatFlags]::HorizontalCenter -bor `
                 [System.Windows.Forms.TextFormatFlags]::VerticalCenter
        [System.Windows.Forms.TextRenderer]::DrawText($e.Graphics,
            $s.TabPages[$e.Index].Text, $e.Font, $e.Bounds, $fg, $flags)
    })

    $script:Tips = New-Object System.Windows.Forms.ToolTip

    $script:status = New-Object System.Windows.Forms.StatusStrip
    $script:status.BackColor = $T.Panel
    $script:status.ForeColor = $T.Text
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
