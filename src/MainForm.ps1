# WipeReady main window shell (header, custom nav, pages, status bar)
# Layout only. No data collection and no export logic here.
# Navigation is a custom button row (not TabControl): no OS-themed chrome,
# so there is no white frame, no strip and nothing to owner-draw.

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

    $script:NavTable = New-Object System.Windows.Forms.TableLayoutPanel
    $script:NavTable.Location = New-Object System.Drawing.Point(10, 74)
    $script:NavTable.Size = New-Object System.Drawing.Size(904, 42)
    $script:NavTable.Anchor = 'Top, Left, Right'
    $script:NavTable.BackColor = $T.Bg
    $script:NavTable.ColumnCount = 0
    $script:NavTable.RowCount = 1
    $script:NavTable.RowStyles.Add((New-Object System.Windows.Forms.RowStyle(
        [System.Windows.Forms.SizeType]::Absolute, 42))) | Out-Null
    $script:form.Controls.Add($script:NavTable)

    $script:PagesPanel = New-Object System.Windows.Forms.Panel
    $script:PagesPanel.Location = New-Object System.Drawing.Point(10, 122)
    $script:PagesPanel.Size = New-Object System.Drawing.Size(904, 434)
    $script:PagesPanel.Anchor = 'Top, Bottom, Left, Right'
    $script:PagesPanel.BackColor = $T.Bg
    $script:form.Controls.Add($script:PagesPanel)

    $script:PagePanels = @()
    $script:NavButtons = @()

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

    $script:form.Add_FormClosed({
        foreach ($f in @($FontUI, $FontTitle, $FontSection, $FontMono, $FontBoldUI)) {
            if ($f) { $f.Dispose() }
        }
    })
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
    [void]$script:form.Handle
    Set-DarkTitleBar $script:form
    [void]$script:form.ShowDialog()
}
