# WipeReady "Restore" tab: after-format steps + winget export
# Same step texts, same command, same reinstall.json output.

function Add-RestoreTab {
    $tab = New-Object System.Windows.Forms.Panel
    $tab.BackColor = $T.Bg
    $tab.Padding = New-Object System.Windows.Forms.Padding(12)
    $tab.AutoScroll = $true
    # Parent now (not in Register-Page): keeps binding mechanics identical
    # across tabs (see Programs).
    $script:PagesPanel.Controls.Add($tab)

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
            if ($LASTEXITCODE -ne 0) { throw "winget export failed (exit $LASTEXITCODE)." }
            Set-Status 'reinstall.json created. After formatting: winget import -i reinstall.json' -Kind Success
        } catch {
            Set-Status 'Winget export failed.' -Kind Error
            [void][System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'WipeReady')
        }
    })
    $row.Controls.Add($btnWinget)
    Add-Tip $btnWinget 'Writes reinstall.json with exact versions to Desktop\wipeready'

    $btnOpen = New-StyledButton 'Open folder'
    $btnOpen.Add_Click({ Invoke-Item $script:OutDir | Out-Null })
    $row.Controls.Add($btnOpen)

    $btnSetup = New-StyledButton 'Make setup script'
    $btnSetup.Add_Click({
        try {
            $p = Write-SetupScript
            Set-Status 'setup.ps1 created. Run it as admin on the formatted PC.' -Kind Success
        } catch {
            Set-Status 'Setup script failed.' -Kind Error
            [void][System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'WipeReady')
        }
    })
    $row.Controls.Add($btnSetup)
    Add-Tip $btnSetup 'Generates setup.ps1: winget import + Wi-Fi + drivers for the new install'

    $btnDrvNow = New-StyledButton 'Install drivers'
    $btnDrvNow.Add_Click({ Install-SavedDrivers })
    $row.Controls.Add($btnDrvNow)
    Add-Tip $btnDrvNow 'Installs the saved drivers on this PC (pnputil)'

    $btnVerify = New-StyledButton 'Verify backup'
    $btnVerify.Add_Click({ Confirm-BackupReady })
    $row.Controls.Add($btnVerify)
    Add-Tip $btnVerify 'Checks drivers, Wi-Fi, winget list and selection before formatting'

    $btnZip = New-StyledButton 'Export .zip'
    $btnZip.Add_Click({
        try {
            Set-Status 'Compressing everything...' -Kind Busy
            $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
            $zip = Join-Path ([Environment]::GetFolderPath('Desktop')) ("wipeready-" + $stamp + ".zip")
            Compress-Archive -Path (Join-Path $script:OutDir '*') -DestinationPath $zip -Force
            $mb = [math]::Round((Get-Item $zip).Length / 1MB, 1)
            Set-Status "All exported to $zip ($mb MB)." -Kind Success
        } catch {
            Set-Status 'Zip export failed.' -Kind Error
            [void][System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'WipeReady')
        }
    })
    $row.Controls.Add($btnZip)
    Add-Tip $btnZip 'Packs the whole wipeready folder into one zip on the Desktop'

    $note = New-OutputNote ''
    $note.Location = New-Object System.Drawing.Point(14, 96)
    $cardAct.Controls.Add($note)

    # ---- Post-format checklist (persisted to checklist.json) ----
    $cardCheck = New-Card
    $cardCheck.Location = New-Object System.Drawing.Point(12, 384)
    $cardCheck.Size = New-Object System.Drawing.Size(880, 196)
    $cardCheck.Anchor = 'Top, Left, Right'
    $tab.Controls.Add($cardCheck)

    $cardCheck.Controls.Add((New-CardTitle 'Post-format checklist'))

    $cl = New-Object System.Windows.Forms.CheckedListBox
    $cl.Location = New-Object System.Drawing.Point(14, 48)
    $cl.Size = New-Object System.Drawing.Size(852, 134)
    $cl.Anchor = 'Top, Left, Right'
    $cl.BackColor = $T.Panel
    $cl.ForeColor = $T.Text
    $cl.BorderStyle = 'None'
    $cl.Font = $FontUI
    $cl.CheckOnClick = $true
    $items = @(
        'Drivers installed',
        'Programs reinstalled (winget import)',
        'Wi-Fi profiles restored',
        'Files copied back from external drive',
        'Windows activated',
        'Windows Update done'
    )
    foreach ($text in $items) { [void]$cl.Items.Add($text) }
    $cardCheck.Controls.Add($cl)
    $script:CheckList = $cl

    $chkPath = Join-Path $script:OutDir 'checklist.json'
    if (Test-Path $chkPath) {
        try {
            $saved = Get-Content $chkPath -Raw | ConvertFrom-Json
            for ($i = 0; $i -lt $cl.Items.Count; $i++) {
                if ($saved -contains $cl.Items[$i]) { $cl.SetItemChecked($i, $true) }
            }
        } catch { }
    }

    $cl.Add_ItemCheck({
        param($sender, $e)
        $done = @()
        for ($i = 0; $i -lt $sender.Items.Count; $i++) {
            $isChecked = if ($i -eq $e.Index) { $e.NewValue -eq 'Checked' } else { $sender.GetItemChecked($i) }
            if ($isChecked) { $done += $sender.Items[$i] }
        }
        ConvertTo-Json -InputObject @($done) | Out-File (Join-Path $script:OutDir 'checklist.json') -Encoding UTF8
    })
    return $tab
}

# Generates setup.ps1: one-shot restore (winget + Wi-Fi + drivers) for the
# formatted PC. Returns the script path. Testable without running it.
function Write-SetupScript {
    $lines = @(
        '#Requires -RunAsAdministrator',
        '# Generated by WipeReady - copy the whole wipeready folder, then run this as admin.',
        '$here = Split-Path -Parent $PSCommandPath',
        'winget import -i (Join-Path $here ''reinstall.json'') --accept-source-agreements --accept-package-agreements',
        'Get-ChildItem (Join-Path $here ''wifi'') -Filter *.xml | ForEach-Object { netsh wlan add profile filename="$($_.FullName)" | Out-Null }',
        '$drv = Join-Path $here ''drivers''',
        'if (Test-Path $drv) { pnputil /add-driver "$drv\*.inf" /subdirs /install }',
        'Write-Host ''Done. Remaining manual steps: see selection.csv and the WipeReady checklist.'''
    )
    $p = Join-Path $script:OutDir 'setup.ps1'
    $lines | Out-File $p -Encoding ASCII
    return $p
}

function Install-SavedDrivers {
    try {
        $drv = Join-Path $script:OutDir 'drivers'
        if (-not (Test-Path $drv)) {
            [void][System.Windows.Forms.MessageBox]::Show('No drivers folder. Export drivers first (Summary tab).', 'WipeReady')
            return
        }
        Set-Status 'Installing saved drivers (pnputil)...' -Kind Busy
        pnputil /add-driver "$drv\*.inf" /subdirs /install | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "pnputil failed (exit $LASTEXITCODE)." }
        Set-Status 'Drivers installed.' -Kind Success
    } catch {
        Set-Status 'Driver install failed.' -Kind Error
        [void][System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'WipeReady')
    }
}

# Pre-format readiness check: drivers, Wi-Fi, winget list, selection.
function Confirm-BackupReady {
    $checks = @(
        @{ Name = 'Drivers (any .inf)'; Ok = @(Get-ChildItem (Join-Path $script:OutDir 'drivers') -Filter *.inf -Recurse -ErrorAction SilentlyContinue).Count -gt 0 },
        @{ Name = 'Wi-Fi profiles (any .xml)'; Ok = @(Get-ChildItem (Join-Path $script:OutDir 'wifi') -Filter *.xml -ErrorAction SilentlyContinue).Count -gt 0 },
        @{ Name = 'reinstall.json'; Ok = Test-Path (Join-Path $script:OutDir 'reinstall.json') },
        @{ Name = 'selection.csv'; Ok = Test-Path (Join-Path $script:OutDir 'selection.csv') }
    )
    $missing = @($checks | Where-Object { -not $_.Ok })
    $lines = foreach ($c in $checks) {
        if ($c.Ok) { '[OK] ' + $c.Name } else { '[MISS] ' + $c.Name }
    }
    if ($missing.Count -eq 0) {
        Set-Status 'Backup check passed: safe to format.' -Kind Success
    } else {
        Set-Status 'Backup check found gaps. See details.' -Kind Warn
    }
    [void][System.Windows.Forms.MessageBox]::Show(($lines -join "`r`n"), 'WipeReady')
}
