# WipeReady "Summary" tab: machine info cards + export actions
# Same data (Get-HardwareSummary) and same handlers/outputs as before.

function Add-SummaryTab {
    $tab = New-Object System.Windows.Forms.TabPage
    $tab.Text = 'Summary'
    $tab.BackColor = $T.Bg
    $tab.Padding = New-Object System.Windows.Forms.Padding(12)
    $tab.AutoScroll = $true
    $script:tabs.TabPages.Add($tab) | Out-Null

    $tab.Controls.Add((New-SectionHeader 'Machine summary' 'Hardware, OS and product key collected from this PC.'))

    # ---- This PC card (same Get-HardwareSummary data, key/value grid) ----
    $cardInfo = New-Card
    $cardInfo.Location = New-Object System.Drawing.Point(12, 74)
    $cardInfo.Size = New-Object System.Drawing.Size(880, 230)
    $cardInfo.Anchor = 'Top, Left, Right'
    $tab.Controls.Add($cardInfo)

    $cardInfo.Controls.Add((New-CardTitle 'This PC'))

    $grid2 = New-Object System.Windows.Forms.TableLayoutPanel
    $grid2.Location = New-Object System.Drawing.Point(14, 48)
    $grid2.Size = New-Object System.Drawing.Size(852, 168)
    $grid2.Anchor = 'Top, Left, Right'
    $grid2.BackColor = $T.Panel
    $grid2.ColumnCount = 2
    $grid2.RowCount = 7
    [void]$grid2.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle(
        [System.Windows.Forms.SizeType]::Absolute, 150)))
    [void]$grid2.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle(
        [System.Windows.Forms.SizeType]::Percent, 100)))
    for ($i = 0; $i -lt 7; $i++) {
        [void]$grid2.RowStyles.Add((New-Object System.Windows.Forms.RowStyle(
            [System.Windows.Forms.SizeType]::Absolute, 24)))
    }
    $cardInfo.Controls.Add($grid2)

    $hw = Get-HardwareSummary
    $r = 0
    foreach ($kv in $hw.GetEnumerator()) {
        $k = New-Object System.Windows.Forms.Label
        $k.Text = $kv.Key
        $k.Font = $FontUI
        $k.ForeColor = $T.Muted
        $k.Dock = 'Fill'
        $k.TextAlign = 'MiddleLeft'
        $grid2.Controls.Add($k, 0, $r)
        $v = New-Object System.Windows.Forms.Label
        $v.Text = "$($kv.Value)"
        $v.Font = $FontUI
        $v.ForeColor = $T.Text
        $v.Dock = 'Fill'
        $v.TextAlign = 'MiddleLeft'
        $v.AutoEllipsis = $true
        $grid2.Controls.Add($v, 1, $r)
        $r++
    }

    # ---- Exports card (same three actions, same outputs) ----
    $cardExp = New-Card
    $cardExp.Location = New-Object System.Drawing.Point(12, 312)
    $cardExp.Size = New-Object System.Drawing.Size(880, 128)
    $cardExp.Anchor = 'Top, Left, Right'
    $tab.Controls.Add($cardExp)

    $cardExp.Controls.Add((New-CardTitle 'Exports'))

    $row = New-Object System.Windows.Forms.FlowLayoutPanel
    $row.Location = New-Object System.Drawing.Point(14, 48)
    $row.Size = New-Object System.Drawing.Size(852, 44)
    $row.Anchor = 'Top, Left, Right'
    $row.BackColor = $T.Panel
    $row.FlowDirection = 'LeftToRight'
    $row.WrapContents = $true
    $cardExp.Controls.Add($row)

    $btnDrivers = New-StyledButton 'Export drivers' -Primary
    $btnDrivers.Add_Click({
        try {
            Set-Status 'Exporting drivers... (may take a while)' -Kind Busy
            Export-WindowsDriver -Online -Destination (Join-Path $script:OutDir 'drivers') | Out-Null
            Set-Status 'Drivers exported to wipeready\drivers.' -Kind Success
        } catch {
            Set-Status 'Driver export failed.' -Kind Error
            [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'WipeReady')
        }
    })
    $row.Controls.Add($btnDrivers)
    Add-Tip $btnDrivers 'Saves installed third-party drivers to wipeready\drivers'

    $btnWifi = New-StyledButton 'Export Wi-Fi'
    $btnWifi.Add_Click({
        $w = Join-Path $script:OutDir 'wifi'
        netsh wlan export profile folder="$w" key=clear | Out-Null
        Set-Status 'Wi-Fi profiles exported to wipeready\wifi.' -Kind Success
    })
    $row.Controls.Add($btnWifi)
    Add-Tip $btnWifi 'Saves Wi-Fi profiles with keys to wipeready\wifi'

    $btnHtml = New-StyledButton 'HTML report'
    $btnHtml.Add_Click({
        Set-Status 'Generating report...' -Kind Busy
        $css = '<style>body{font-family:"Segoe UI";background:#0f172a;color:#e2e8f0;padding:24px}h2{color:#38bdf8;border-bottom:1px solid #334155}table{border-collapse:collapse;width:100%;margin-bottom:24px}th{background:#1e293b;text-align:left;padding:6px}td{border-bottom:1px solid #1e293b;padding:6px;font-size:13px}.card{background:#1e293b;padding:12px;border-radius:8px;margin-bottom:16px}</style>'
        $progs = Get-InstalledPrograms
        $folders = Get-UserFolderSizes
        $startup = Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, User
        $info = Get-HardwareSummary
        $html = "<html><head><meta charset='utf-8'>$css</head><body><h1>PC Inventory</h1>"
        $html += "<div class='card'>" + (($info.GetEnumerator() | ForEach-Object { "<b>$($_.Key):</b> $($_.Value)" }) -join '<br>') + '</div>'
        $html += '<h2>Programs</h2>' + ($progs | ConvertTo-Html -Fragment)
        $html += '<h2>Folders (GB)</h2>' + ($folders | ConvertTo-Html -Fragment)
        $html += '<h2>Startup</h2>' + ($startup | ConvertTo-Html -Fragment)
        $html += '</body></html>'
        $html | Out-File (Join-Path $script:OutDir 'report.html') -Encoding UTF8
        Set-Status 'Report generated and opened in the browser.' -Kind Success
        Invoke-Item (Join-Path $script:OutDir 'report.html')
    })
    $row.Controls.Add($btnHtml)
    Add-Tip $btnHtml 'Builds report.html with programs, folders and startup items'

    $note = New-OutputNote ''
    $note.Location = New-Object System.Drawing.Point(14, 96)
    $cardExp.Controls.Add($note)
}
