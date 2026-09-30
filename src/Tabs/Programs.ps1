# WipeReady "Programs" tab: searchable checklist of installed programs
# Same data source, same selection.json/selection.csv outputs.

function Add-ProgramsTab {
    $tab = New-Object System.Windows.Forms.TabPage
    $tab.Text = 'Programs'
    $tab.BackColor = $T.Bg
    $tab.Padding = New-Object System.Windows.Forms.Padding(12)
    $tab.AutoScroll = $true
    $script:tabs.TabPages.Add($tab) | Out-Null

    $tab.Controls.Add((New-SectionHeader 'Installed programs' 'Check what to keep. Save writes selection.json and selection.csv.'))

    # ---- Search row (filters the already-loaded table, no new collection) ----
    $searchPanel = New-Object System.Windows.Forms.Panel
    $searchPanel.Location = New-Object System.Drawing.Point(12, 74)
    $searchPanel.Size = New-Object System.Drawing.Size(880, 30)
    $searchPanel.Anchor = 'Top, Left, Right'
    $searchPanel.BackColor = $T.Bg
    $tab.Controls.Add($searchPanel)

    $lblSearch = New-Object System.Windows.Forms.Label
    $lblSearch.Text = 'Search'
    $lblSearch.Font = $FontUI
    $lblSearch.ForeColor = $T.Muted
    $lblSearch.Location = New-Object System.Drawing.Point(0, 4)
    $lblSearch.AutoSize = $true
    $searchPanel.Controls.Add($lblSearch)

    $txtSearch = New-Object System.Windows.Forms.TextBox
    $txtSearch.Location = New-Object System.Drawing.Point(64, 3)
    $txtSearch.Size = New-Object System.Drawing.Size(600, 23)
    $txtSearch.Anchor = 'Top, Left, Right'
    $txtSearch.Font = $FontUI
    $txtSearch.BackColor = $T.Panel
    $txtSearch.ForeColor = $T.Text
    $txtSearch.BorderStyle = 'FixedSingle'
    $searchPanel.Controls.Add($txtSearch)
    Add-Tip $txtSearch 'Type to filter the program list below'

    $lblCount = New-Object System.Windows.Forms.Label
    $lblCount.Location = New-Object System.Drawing.Point(676, 4)
    $lblCount.Size = New-Object System.Drawing.Size(204, 20)
    $lblCount.Anchor = 'Top, Right'
    $lblCount.Font = $FontUI
    $lblCount.ForeColor = $T.Accent
    $lblCount.TextAlign = 'MiddleRight'
    $searchPanel.Controls.Add($lblCount)
    $script:ProgramsCountLabel = $lblCount

    $txtSearch.Add_TextChanged({
        $q = $txtSearch.Text.Replace("'", "''").Replace('[', '[[]').Replace('%', '[%]').Replace('*', '[*]')
        if ([string]::IsNullOrWhiteSpace($q)) {
            $script:ProgramsTable.DefaultView.RowFilter = ''
        } else {
            $script:ProgramsTable.DefaultView.RowFilter = "Program LIKE '%$q%'"
        }
    })

    # ---- Grid (same binding and columns as before) ----
    $grid = New-Object System.Windows.Forms.DataGridView
    $grid.Location = New-Object System.Drawing.Point(12, 110)
    $grid.Size = New-Object System.Drawing.Size(880, 230)
    $grid.Anchor = 'Top, Bottom, Left, Right'
    $tab.Controls.Add($grid)

    $script:ProgramsTable = New-Object System.Data.DataTable
    [void]$script:ProgramsTable.Columns.Add('Keep', [bool])
    [void]$script:ProgramsTable.Columns.Add('Program', [string])
    [void]$script:ProgramsTable.Columns.Add('Version', [string])
    [void]$script:ProgramsTable.Columns.Add('Publisher', [string])
    foreach ($p in (Get-InstalledPrograms)) {
        $row = $script:ProgramsTable.NewRow()
        $row['Keep'] = $true
        $row['Program'] = $p.DisplayName
        $row['Version'] = $p.DisplayVersion
        $row['Publisher'] = $p.Publisher
        $script:ProgramsTable.Rows.Add($row) | Out-Null
    }
    $grid.DataSource = $script:ProgramsTable
    $grid.Columns['Keep'].ReadOnly = $false
    $grid.Columns['Program'].ReadOnly = $true
    $grid.Columns['Version'].ReadOnly = $true
    $grid.Columns['Publisher'].ReadOnly = $true
    Style-Grid $grid
    $grid.Columns['Keep'].FillWeight = 18
    $grid.Columns['Program'].FillWeight = 52
    $grid.Columns['Version'].FillWeight = 15
    $grid.Columns['Publisher'].FillWeight = 15

    $grid.Add_CurrentCellDirtyStateChanged({
        if ($grid.IsCurrentCellDirty) { [void]$grid.CommitEdit('Commit') }
    })
    $grid.Add_CellValueChanged({ Update-ProgramsCount })
    Update-ProgramsCount

    # ---- Bottom actions ----
    $row = New-ButtonRow 348 880
    $row.Anchor = 'Bottom, Left, Right'
    $tab.Controls.Add($row)

    $btnAll = New-StyledButton 'Check all' 140
    $btnAll.Add_Click({
        foreach ($r in $script:ProgramsTable.Rows) { $r['Keep'] = $true }
        Update-ProgramsCount
    })
    $row.Controls.Add($btnAll)

    $btnNone = New-StyledButton 'Uncheck all' 140
    $btnNone.Add_Click({
        foreach ($r in $script:ProgramsTable.Rows) { $r['Keep'] = $false }
        Update-ProgramsCount
    })
    $row.Controls.Add($btnNone)

    $btnSave = New-StyledButton 'Save selection' 140 -Primary
    $btnSave.Add_Click({
        $sel = @($script:ProgramsTable.Rows | Where-Object { $_['Keep'] -eq $true } | ForEach-Object {
            [pscustomobject]@{ Program = $_['Program']; Version = $_['Version']; Publisher = $_['Publisher'] }
        })
        $sel | ConvertTo-Json -Depth 3 | Out-File (Join-Path $script:OutDir 'selection.json') -Encoding UTF8
        $sel | Export-Csv (Join-Path $script:OutDir 'selection.csv') -NoTypeInformation -Encoding UTF8
        Set-Status "Selection saved: $($sel.Count) programs." -Kind Success
        [System.Windows.Forms.MessageBox]::Show("Selection saved ($($sel.Count) programs).", 'WipeReady')
    })
    $row.Controls.Add($btnSave)
    Add-Tip $btnSave 'Writes selection.json and selection.csv to Desktop\wipeready'

    $note = New-OutputNote ''
    $note.Location = New-Object System.Drawing.Point(12, 398)
    $note.Anchor = 'Bottom, Left, Right'
    $tab.Controls.Add($note)
}

function Update-ProgramsCount {
    $total = $script:ProgramsTable.Rows.Count
    $kept = @($script:ProgramsTable.Rows | Where-Object { $_['Keep'] -eq $true }).Count
    $script:ProgramsCountLabel.Text = "$kept of $total selected"
}
