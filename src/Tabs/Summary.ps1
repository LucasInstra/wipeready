# WipeReady "Summary" tab: machine info, driver/Wi-Fi export, HTML report

function Add-SummaryTab {
    $tab = New-Object System.Windows.Forms.TabPage
    $tab.Text = 'Summary'
    $tab.BackColor = $T.Bg
    $tab.Padding = New-Object System.Windows.Forms.Padding(12)
    $script:tabs.TabPages.Add($tab) | Out-Null

    $txt = New-Object System.Windows.Forms.TextBox
    $txt.Multiline = $true
    $txt.ReadOnly = $true
    $txt.ScrollBars = 'Vertical'
    $txt.Font = $FontMono
    $txt.BackColor = $T.Bg
    $txt.ForeColor = $T.Text
    $txt.BorderStyle = 'FixedSingle'
    $txt.Dock = 'Top'
    $txt.Height = 300
    $tab.Controls.Add($txt)

    $hw = Get-HardwareSummary
    $txt.Lines = $hw.GetEnumerator() | ForEach-Object { "$($_.Key): $($_.Value)" }

    $btnDrivers = New-StyledButton 'Export drivers' 12 322
    $btnDrivers.Add_Click({
        try {
            Set-Status 'Exporting drivers... (may take a while)'
            Export-WindowsDriver -Online -Destination (Join-Path $script:OutDir 'drivers') | Out-Null
            Set-Status 'Drivers exported to wipeready\drivers.'
        } catch {
            Set-Status 'Driver export failed.'
            [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'WipeReady')
        }
    })
    $tab.Controls.Add($btnDrivers)

    $btnWifi = New-StyledButton 'Export Wi-Fi' 194 322
    $btnWifi.Add_Click({
        $w = Join-Path $script:OutDir 'wifi'
        netsh wlan export profile folder="$w" key=clear | Out-Null
        Set-Status 'Wi-Fi profiles exported to wipeready\wifi.'
    })
    $tab.Controls.Add($btnWifi)

    $btnHtml = New-StyledButton 'HTML report' 376 322
    $btnHtml.Add_Click({
        Set-Status 'Generating report...'
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
        Set-Status 'Report generated and opened in the browser.'
        Invoke-Item (Join-Path $script:OutDir 'report.html')
    })
    $tab.Controls.Add($btnHtml)
}
