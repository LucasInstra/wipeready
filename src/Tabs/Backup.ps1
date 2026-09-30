# WipeReady "Backup" tab: pick user folders and copy them to an external drive

function Add-BackupTab {
    $tab = New-Object System.Windows.Forms.TabPage
    $tab.Text = 'Backup'
    $tab.BackColor = $T.Bg
    $tab.Padding = New-Object System.Windows.Forms.Padding(12)
    $script:tabs.TabPages.Add($tab) | Out-Null

    $lst = New-Object System.Windows.Forms.ListView
    $lst.View = 'Details'
    $lst.FullRowSelect = $true
    $lst.CheckBoxes = $true
    $lst.Dock = 'Top'
    $lst.Height = 280
    $lst.BackColor = $T.Bg
    $lst.ForeColor = $T.Text
    $lst.BorderStyle = 'None'
    $lst.Font = $FontUI
    [void]$lst.Columns.Add('Folder', 320)
    [void]$lst.Columns.Add('GB', 120)
    $tab.Controls.Add($lst)
    $script:FolderList = $lst

    $lblTotal = New-Object System.Windows.Forms.Label
    $lblTotal.Text = 'Selected for backup: 0 GB'
    $lblTotal.AutoSize = $true
    $lblTotal.Location = New-Object System.Drawing.Point(14, 336)
    $lblTotal.ForeColor = $T.Accent
    $lblTotal.Font = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)
    $tab.Controls.Add($lblTotal)
    $script:BackupTotalLabel = $lblTotal

    $lst.Add_ItemChecked({ Update-BackupTotal })

    $btnScan = New-StyledButton 'Scan folders' 12 296
    $btnScan.Add_Click({
        Set-Status 'Scanning folders... (may take a while depending on file volume)'
        $script:form.Refresh()
        $script:FolderList.Items.Clear()
        foreach ($f in (Get-UserFolderSizes)) {
            $item = New-Object System.Windows.Forms.ListViewItem($f.Folder)
            [void]$item.SubItems.Add("$($f.GB)")
            if ($f.Folder -ne 'AppData') { $item.Checked = $true }
            $script:FolderList.Items.Add($item) | Out-Null
        }
        Update-BackupTotal
        Set-Status 'Scan complete. Uncheck anything that should not go to backup.'
    })
    $tab.Controls.Add($btnScan)

    $btnCopy = New-StyledButton 'Copy to external drive' 194 296 200
    $btnCopy.Add_Click({
        $sel = @($script:FolderList.CheckedItems)
        if ($sel.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show('Check at least one folder.', 'WipeReady')
            return
        }
        $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
        $dlg.Description = 'Pick the destination folder on the external drive'
        if ($dlg.ShowDialog() -ne 'OK') { return }
        $i = 0
        foreach ($item in $sel) {
            $i++
            $src = Join-Path $env:USERPROFILE $item.Text
            $dst = Join-Path $dlg.SelectedPath $item.Text
            Set-Status "Copying $($item.Text) ($i of $($sel.Count))... keep the app open."
            $script:form.Refresh()
            robocopy "$src" "$dst" /E /R:2 /W:2 /MT:8 /NFL /NDL /NJH /NJS | Out-Null
            if ($LASTEXITCODE -ge 8) {
                [System.Windows.Forms.MessageBox]::Show("Failed to copy $($item.Text).", 'WipeReady')
            }
        }
        Set-Status 'Folder backup complete.'
        [System.Windows.Forms.MessageBox]::Show('Folder backup complete.', 'WipeReady')
    })
    $tab.Controls.Add($btnCopy)

    $btnOpen = New-StyledButton 'Open folder' 406 296 140
    $btnOpen.Add_Click({
        if ($script:FolderList.FocusedItem) {
            Invoke-Item (Join-Path $env:USERPROFILE $script:FolderList.FocusedItem.Text)
        }
    })
    $tab.Controls.Add($btnOpen)

    $tab.Controls.Add((New-SectionLabel 'Check the folders and copy them to the external drive. AppData starts unchecked (programs get reinstalled later). Do not forget the wipeready folder.' 14 360 850))
}

function Update-BackupTotal {
    $total = 0
    foreach ($item in $script:FolderList.CheckedItems) {
        $v = 0
        [void][double]::TryParse($item.SubItems[1].Text, [ref]$v)
        $total += $v
    }
    $script:BackupTotalLabel.Text = "Selected for backup: $([math]::Round($total, 2)) GB"
}
