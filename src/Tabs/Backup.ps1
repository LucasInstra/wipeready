# WipeReady "Backup" tab: pick user folders and copy them to an external drive
# Same scan, same robocopy arguments, same outputs. Only layout changed.

function Add-BackupTab {
    $tab = New-Object System.Windows.Forms.Panel
    $tab.BackColor = $T.Bg
    $tab.Padding = New-Object System.Windows.Forms.Padding(12)
    $tab.AutoScroll = $true
    # Parent now (not in Register-Page): keeps binding mechanics identical
    # across tabs (see Programs).
    $script:PagesPanel.Controls.Add($tab)
    # Size the tab to its final docked size BEFORE adding children: anchor
    # margins are captured when a control is added, and a default-sized
    # tab would record negative margins (children would then overflow).
    $tab.Size = $script:PagesPanel.ClientSize

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
        try {
            Set-Status 'Scanning folders... (may take a while depending on file volume)' -Kind Busy
            $script:form.Refresh()
            $script:FolderList.Items.Clear()
            foreach ($f in (Get-UserFolderSizes)) {
                $item = New-Object System.Windows.Forms.ListViewItem($f.Folder)
                [void]$item.SubItems.Add("$($f.GB)")
                # Numeric value on Tag: no culture-dependent text round-trip.
                $item.Tag = [double]$f.GB
                if ($f.Folder -ne 'AppData') { $item.Checked = $true }
                $script:FolderList.Items.Add($item) | Out-Null
            }
            $script:BackupEmptyHint.Visible = $false
            Update-BackupTotal
            Set-Status 'Scan complete. Uncheck anything that should not go to backup.' -Kind Success
        } catch {
            Set-Status 'Folder scan failed.' -Kind Error
            [void][System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'WipeReady')
        }
    })
    $bar.Controls.Add($btnScan)
    Add-Tip $btnScan 'Measures each user folder (Desktop, Documents, ...)'

    $btnCopy = New-StyledButton 'Copy to external drive' 200 -Primary
    $btnCopy.Add_Click({
        $sel = @($script:FolderList.CheckedItems)
        if ($sel.Count -eq 0) {
            [void][System.Windows.Forms.MessageBox]::Show('Check at least one folder.', 'WipeReady')
            return
        }
        $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
        $dlg.Description = 'Pick the destination folder on the external drive'
        if ($dlg.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }
        $i = 0
        $failed = $false
        foreach ($item in $sel) {
            $i++
            $src = Join-Path $env:USERPROFILE $item.Text
            $dst = Join-Path $dlg.SelectedPath $item.Text
            Set-Status "Copying $($item.Text) ($i of $($sel.Count))... keep the app open." -Kind Busy
            $script:form.Refresh()
            robocopy "$src" "$dst" /E /R:2 /W:2 /MT:8 /NFL /NDL /NJH /NJS | Out-Null
            if ($LASTEXITCODE -ge 8) {
                $failed = $true
                [void][System.Windows.Forms.MessageBox]::Show("Failed to copy $($item.Text).", 'WipeReady')
            }
        }
        if ($failed) {
            Set-Status 'Backup finished with errors. Check the messages above.' -Kind Warn
            [void][System.Windows.Forms.MessageBox]::Show('Backup finished with errors.', 'WipeReady')
        } else {
            Set-Status 'Folder backup complete.' -Kind Success
            [void][System.Windows.Forms.MessageBox]::Show('Folder backup complete.', 'WipeReady')
        }
    })
    $bar.Controls.Add($btnCopy)
    Add-Tip $btnCopy 'Copies checked folders to the drive you pick'

    $btnOpen = New-StyledButton 'Open folder' 140
    $btnOpen.Add_Click({
        if ($script:FolderList.FocusedItem) {
            Invoke-Item (Join-Path $env:USERPROFILE $script:FolderList.FocusedItem.Text) | Out-Null
        }
    })
    $bar.Controls.Add($btnOpen)

    $btnBrowsers = New-StyledButton 'Backup browsers' 170
    $btnBrowsers.Add_Click({ Backup-BrowserProfiles })
    $bar.Controls.Add($btnBrowsers)
    Add-Tip $btnBrowsers 'Copies Chrome, Edge and Firefox profiles (bookmarks, passwords, extensions)'

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
        if ($item.Tag -is [double]) { $total += $item.Tag }
    }
    $script:BackupTotalLabel.Text = "Selected for backup: $([math]::Round($total, 2)) GB"
}

# Copies Chrome/Edge/Firefox profiles (bookmarks, saved passwords,
# extensions). Skips caches. Close the browsers first: locked files
# are skipped. Passwords only restore on the same Windows account.
function Backup-BrowserProfiles {
    try {
        Set-Status 'Backing up browser profiles...' -Kind Busy
        $dest = Join-Path $script:OutDir 'browsers'
        $found = 0
        $chromium = @(
            @{ Name = 'Chrome'; Path = (Join-Path $env:LOCALAPPDATA 'Google\Chrome\User Data\Default') },
            @{ Name = 'Edge'; Path = (Join-Path $env:LOCALAPPDATA 'Microsoft\Edge\User Data\Default') }
        )
        foreach ($b in $chromium) {
            if (Test-Path $b.Path) {
                $found++
                robocopy $b.Path (Join-Path $dest $b.Name) /E /R:2 /W:2 /MT:8 /NFL /NDL /NJH /NJS `
                    /XD 'Cache' 'Code Cache' 'GPUCache' 'ShaderCache' 'Service Worker Cache' | Out-Null
            }
        }
        $ffRoot = Join-Path $env:APPDATA 'Mozilla\Firefox\Profiles'
        if (Test-Path $ffRoot) {
            foreach ($prof in (Get-ChildItem $ffRoot -Directory -Filter '*.default*')) {
                $found++
                robocopy $prof.FullName (Join-Path $dest ('Firefox-' + $prof.Name)) /E /R:2 /W:2 /MT:8 /NFL /NDL /NJH /NJS `
                    /XD 'cache2' 'startupCache' | Out-Null
            }
        }
        if ($found -eq 0) {
            Set-Status 'No browser profiles found.' -Kind Warn
        } else {
            Set-Status "Browser profiles saved to wipeready\browsers ($found). Close browsers first for a complete copy." -Kind Success
        }
    } catch {
        Set-Status 'Browser backup failed.' -Kind Error
        [void][System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'WipeReady')
    }
}
