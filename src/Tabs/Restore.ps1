# WipeReady "Restore" tab: winget export + after-format checklist

function Add-RestoreTab {
    $tab = New-Object System.Windows.Forms.TabPage
    $tab.Text = 'Restore'
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
    $txt.Text = "1. Install Windows from the ISO.`r`n2. Run: winget import -i reinstall.json`r`n3. Reinstall the rest from selection.csv.`r`n4. Check the saved drivers and Wi-Fi."
    $tab.Controls.Add($txt)

    $btnWinget = New-StyledButton 'Export winget' 12 322
    $btnWinget.Add_Click({
        try {
            Set-Status 'Exporting winget list...'
            winget export -o (Join-Path $script:OutDir 'reinstall.json') --include-versions
            Set-Status 'reinstall.json created. After formatting: winget import -i reinstall.json'
        } catch {
            Set-Status 'Winget export failed.'
            [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'WipeReady')
        }
    })
    $tab.Controls.Add($btnWinget)

    $btnOpen = New-StyledButton 'Open folder' 194 322
    $btnOpen.Add_Click({ Invoke-Item $script:OutDir })
    $tab.Controls.Add($btnOpen)
}
