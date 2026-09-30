# WipeReady "Restore" tab: after-format steps + winget export
# Same step texts, same command, same reinstall.json output.

function Add-RestoreTab {
    $tab = New-Object System.Windows.Forms.Panel
    $tab.BackColor = $T.Bg
    $tab.Padding = New-Object System.Windows.Forms.Padding(12)
    $tab.AutoScroll = $true

    $tab.Controls.Add((New-SectionHeader 'After formatting' 'Reinstall in order. Everything the app saved lives in Desktop\wipeready.'))

    # ---- Steps card (same four instructions, numbered) ----
    $cardSteps = New-Card
    $cardSteps.Location = New-Object System.Drawing.Point(12, 74)
    $cardSteps.Size = New-Object System.Drawing.Size(880, 166)
    $cardSteps.Anchor = 'Top, Left, Right'
    $tab.Controls.Add($cardSteps)

    $cardSteps.Controls.Add((New-CardTitle 'Steps'))

    $steps = New-Object System.Windows.Forms.TableLayoutPanel
    $steps.Location = New-Object System.Drawing.Point(14, 48)
    $steps.Size = New-Object System.Drawing.Size(852, 104)
    $steps.Anchor = 'Top, Left, Right'
    $steps.BackColor = $T.Panel
    $steps.ColumnCount = 2
    $steps.RowCount = 4
    [void]$steps.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle(
        [System.Windows.Forms.SizeType]::Absolute, 30)))
    [void]$steps.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle(
        [System.Windows.Forms.SizeType]::Percent, 100)))
    $stepTexts = @(
        'Install Windows from the ISO.',
        'Run: winget import -i reinstall.json',
        'Reinstall the rest from selection.csv.',
        'Check the saved drivers and Wi-Fi.'
    )
    for ($i = 0; $i -lt 4; $i++) {
        [void]$steps.RowStyles.Add((New-Object System.Windows.Forms.RowStyle(
            [System.Windows.Forms.SizeType]::Absolute, 26)))
        $n = New-Object System.Windows.Forms.Label
        $n.Text = "$($i + 1)."
        $n.Font = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)
        $n.ForeColor = $T.Accent
        $n.Dock = 'Fill'
        $n.TextAlign = 'MiddleLeft'
        $steps.Controls.Add($n, 0, $i)
        $s = New-Object System.Windows.Forms.Label
        $s.Text = $stepTexts[$i]
        $s.Font = $FontMono
        $s.ForeColor = $T.Text
        $s.Dock = 'Fill'
        $s.TextAlign = 'MiddleLeft'
        $s.AutoEllipsis = $true
        $steps.Controls.Add($s, 1, $i)
    }
    $cardSteps.Controls.Add($steps)

    # ---- Actions card (same two actions, same outputs) ----
    $cardAct = New-Card
    $cardAct.Location = New-Object System.Drawing.Point(12, 248)
    $cardAct.Size = New-Object System.Drawing.Size(880, 128)
    $cardAct.Anchor = 'Top, Left, Right'
    $tab.Controls.Add($cardAct)

    $cardAct.Controls.Add((New-CardTitle 'Reinstall kit'))

    $row = New-Object System.Windows.Forms.FlowLayoutPanel
    $row.Location = New-Object System.Drawing.Point(14, 48)
    $row.Size = New-Object System.Drawing.Size(852, 44)
    $row.Anchor = 'Top, Left, Right'
    $row.BackColor = $T.Panel
    $row.FlowDirection = 'LeftToRight'
    $row.WrapContents = $true
    $cardAct.Controls.Add($row)

    $btnWinget = New-StyledButton 'Export winget' -Primary
    $btnWinget.Add_Click({
        try {
            Set-Status 'Exporting winget list...' -Kind Busy
            winget export -o (Join-Path $script:OutDir 'reinstall.json') --include-versions | Out-Null
            Set-Status 'reinstall.json created. After formatting: winget import -i reinstall.json' -Kind Success
        } catch {
            Set-Status 'Winget export failed.' -Kind Error
            [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'WipeReady')
        }
    })
    $row.Controls.Add($btnWinget)
    Add-Tip $btnWinget 'Writes reinstall.json with exact versions to Desktop\wipeready'

    $btnOpen = New-StyledButton 'Open folder'
    $btnOpen.Add_Click({ Invoke-Item $script:OutDir })
    $row.Controls.Add($btnOpen)

    $note = New-OutputNote ''
    $note.Location = New-Object System.Drawing.Point(14, 96)
    $cardAct.Controls.Add($note)
    return $tab
}
