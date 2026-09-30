# WipeReady "Backup" tab: pick user folders and copy them to an external drive
# Same scan, same robocopy arguments, same outputs. Only layout changed.

function Add-BackupTab {
    $tab = New-Object System.Windows.Forms.Panel
    $tab.BackColor = $T.Bg
    $tab.Padding = New-Object System.Windows.Forms.Padding(12)
    $tab.AutoScroll = $true

    $tab.Controls.Add((New-SectionHeader 'Folders and backup' 'Scan, check what matters, copy to the external drive. AppData starts unchecked.'))

    # ---- Toolbar ----
    $bar = New-Object System.Windows.Forms.FlowLayoutPanel
    $bar.Location = New-Object System.Drawing.Point(12, 74)
    $bar.Size = New-Object System.Drawing.Size(880, 44)
    $bar.Anchor = 'Top, Left, Right'
    $bar.BackColor = $T.Bg
    $bar.FlowDirection = 'LeftToRight'
    $bar.WrapContents = $true
    $tab.Controls.Add($bar)

    $btnScan = New-StyledButton 'Scan folders'
    $btnScan.Add_Click({
        Set-Status 'Scanning folders... (may take a while depending on file volume)' -Kind Busy
        $script:form.Refresh()
        $script:FolderList.Items.Clear()
        foreach ($f in (Get-UserFolderSizes)) {
            $item = New-Object System.Windows.Forms.ListViewItem($f.Folder)
            [void]$item.SubItems.Add("$($f.GB)")
            if ($f.Folder -ne 'AppData') { $item.Checked = $true }
            $script:FolderList.Items.Add($item) | Out-Null
        }
        $script:BackupEmptyHint.Visible = $false
        Update-BackupTotal
        Set-Status 'Scan complete. Uncheck anything that should not go to backup.' -Kind Success
    })
    $bar.Controls.Add($btnScan)
    Add-Tip $btnScan 'Measures each user folder (Desktop, Documents, ...)'

    $btnCopy = New-StyledButton 'Copy to external drive' 200 -Primary
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
            Set-Status "Copying $($item.Text) ($i of $($sel.Count))... keep the app open." -Kind Busy
            $script:form.Refresh()
            robocopy "$src" "$dst" /E /R:2 /W:2 /MT:8 /NFL /NDL /NJH /NJS | Out-Null
            if ($LASTEXITCODE -ge 8) {
                [System.Windows.Forms.MessageBox]::Show("Failed to copy $($item.Text).", 'WipeReady')
            }
        }
        Set-Status 'Folder backup complete.' -Kind Success
        [System.Windows.Forms.MessageBox]::Show('Folder backup complete.', 'WipeReady')
    })
    $bar.Controls.Add($btnCopy)
    Add-Tip $btnCopy 'Copies checked folders to the drive you pick'

    $btnOpen = New-StyledButton 'Open folder' 140
    $btnOpen.Add_Click({
        if ($script:FolderList.FocusedItem) {
            Invoke-Item (Join-Path $env:USERPROFILE $script:FolderList.FocusedItem.Text)
        }
    })
    $bar.Controls.Add($btnOpen)

    # ---- Folder list (same columns, checkboxes and behavior) ----
    $lst = New-Object System.Windows.Forms.ListView
    $lst.View = 'Details'
    $lst.FullRowSelect = $true
    $lst.CheckBoxes = $true
    $lst.Location = New-Object System.Drawing.Point(12, 124)
    $lst.Size = New-Object System.Drawing.Size(880, 216)
    $lst.Anchor = 'Top, Bottom, Left, Right'
    $lst.BackColor = $T.Bg
    $lst.ForeColor = $T.Text
    $lst.BorderStyle = 'FixedSingle'
    $lst.Font = $FontUI
    [void]$lst.Columns.Add('Folder', 320)
    [void]$lst.Columns.Add('GB', 120)
    $tab.Controls.Add($lst)
    $script:FolderList = $lst

    $lst.Add_ItemChecked({ Update-BackupTotal })

    # ---- Bottom: highlighted total + empty-state hint + guide note ----
    $lblTotal = New-Object System.Windows.Forms.Label
    $lblTotal.Text = 'Selected for backup: 0 GB'
    $lblTotal.AutoSize = $true
    $lblTotal.Location = New-Object System.Drawing.Point(12, 346)
    $lblTotal.Anchor = 'Bottom, Left'
    $lblTotal.ForeColor = $T.Accent
    $lblTotal.Font = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
    $tab.Controls.Add($lblTotal)
    $script:BackupTotalLabel = $lblTotal

    $lblEmpty = New-Object System.Windows.Forms.Label
    $lblEmpty.Text = 'No folders scanned yet — click Scan folders.'
    $lblEmpty.AutoSize = $true
    $lblEmpty.Location = New-Object System.Drawing.Point(12, 372)
    $lblEmpty.Anchor = 'Bottom, Left'
    $lblEmpty.ForeColor = $T.Warn
    $lblEmpty.Font = $FontUI
    $tab.Controls.Add($lblEmpty)
    $script:BackupEmptyHint = $lblEmpty

    $lblGuide = New-Object System.Windows.Forms.Label
    $lblGuide.Text = 'AppData starts unchecked (programs get reinstalled later). Do not forget the wipeready folder.'
    $lblGuide.AutoSize = $false
    $lblGuide.Size = New-Object System.Drawing.Size(880, 20)
    $lblGuide.Location = New-Object System.Drawing.Point(12, 394)
    $lblGuide.Anchor = 'Bottom, Left, Right'
    $lblGuide.ForeColor = $T.Muted
    $lblGuide.Font = $FontUI
    $tab.Controls.Add($lblGuide)
    return $tab
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
