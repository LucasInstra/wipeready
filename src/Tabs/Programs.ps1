# WipeReady "Programs" tab: searchable checklist of installed programs
# Same data source, same selection.json/selection.csv outputs.

function Add-ProgramsTab {
    $tab = New-Object System.Windows.Forms.Panel
    $tab.BackColor = $T.Bg
    $tab.Padding = New-Object System.Windows.Forms.Padding(12)
    $tab.AutoScroll = $true
    # Parent now (not in Register-Page): the grid's data binding needs
    # the form chain to exist before DataSource is set below.
    $script:PagesPanel.Controls.Add($tab)

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
    Add-Tip $txtSearch 'Type to filter the program list below (Down/Tab jumps to the list)'

    $lblCount = New-Object System.Windows.Forms.Label
    $lblCount.Location = New-Object System.Drawing.Point(676, 4)
    $lblCount.Size = New-Object System.Drawing.Size(204, 20)
    $lblCount.Anchor = 'Top, Right'
    $lblCount.Font = $FontUI
    $lblCount.ForeColor = $T.Accent
    $lblCount.TextAlign = 'MiddleRight'
    $searchPanel.Controls.Add($lblCount)
    $script:ProgramsCountLabel = $lblCount

    # NOTE: event handlers run after this function returns, so they must
    # use the sender argument, never function-locals like $txtSearch/$grid.
    $txtSearch.Add_TextChanged({
        param($sender, $e)
        $q = $sender.Text.Replace("'", "''").Replace('[', '[[]').Replace(']', '[]]').Replace('%', '[%]').Replace('*', '[*]')
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
    $script:ProgramsGrid = $grid

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

    # ---- Keyboard: Tab enters/leaves the list, Enter/Space toggles Keep ----
    # Tab order: search (0) -> grid (1) -> buttons (2..5).
    # Containers never take focus so Tab from search lands on the grid.
    $tab.TabStop = $false
    $searchPanel.TabStop = $false
    $txtSearch.TabStop = $true
    $txtSearch.TabIndex = 0
    $grid.TabStop = $true
    $grid.TabIndex = 1
    # StandardTab = true: Tab moves to the next control instead of
    # cycling cell-by-cell inside the grid.
    $grid.StandardTab = $true
    # Keep default EditOnKeystrokeOrF2: with EditOnEnter the checkbox cell
    # stays in edit mode and Down/Enter go to the hosted CheckBox instead
    # of the grid KeyDown handler, so navigation + scroll stop working.
    $grid.EditMode = [System.Windows.Forms.DataGridViewEditMode]::EditOnKeystrokeOrF2
    Add-Tip $grid 'Tab enters/leaves the list. Up/Down moves. Enter/Space toggles Keep. Ctrl+S saves.'

    # Down arrow in the search box jumps to the list below.
    # Ctrl+S here also saves the checked rows.
    $txtSearch.Add_KeyDown({
        param($sender, $e)
        if (($e.Control) -and ($e.KeyCode -eq [System.Windows.Forms.Keys]::S)) {
            Save-ProgramsSelection
            $e.Handled = $true
            $e.SuppressKeyPress = $true
            return
        }
        if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Down) {
            $g = $script:ProgramsGrid
            if ($g -and $g.Rows.Count -gt 0) {
                $g.Focus()
                $ri = 0
                if ($g.CurrentCell) { $ri = $g.CurrentCell.RowIndex }
                if ($ri -lt 0 -or $ri -ge $g.Rows.Count) { $ri = 0 }
                $g.CurrentCell = $g.Rows[$ri].Cells['Keep']
                Set-ProgramsVisibleRow $g $ri
                $e.Handled = $true
                $e.SuppressKeyPress = $true
            }
        }
    })

    # When the grid receives focus via Tab, land on the Keep checkbox
    # of the current row instead of a read-only text cell.
    $grid.Add_Enter({
        param($sender, $e)
        if ($sender.Rows.Count -gt 0) {
            $ri = 0
            if ($sender.CurrentCell) { $ri = $sender.CurrentCell.RowIndex }
            if ($ri -lt 0 -or $ri -ge $sender.Rows.Count) { $ri = 0 }
            if ($sender.Columns.Contains('Keep')) {
                $sender.CurrentCell = $sender.Rows[$ri].Cells['Keep']
            }
        }
    })

    # Enter toggles + advances (checklist flow), Down/Up moves,
    # Space toggles without moving. Every move forces the row into view
    # so the list scrolls along at the last visible row.
    # Ctrl+S saves the checked rows.
    $grid.Add_KeyDown({
        param($sender, $e)
        if (($e.Control) -and ($e.KeyCode -eq [System.Windows.Forms.Keys]::S)) {
            Save-ProgramsSelection
            $e.Handled = $true
            $e.SuppressKeyPress = $true
            return
        }
        $code = $e.KeyCode
        $isToggle = ($code -eq [System.Windows.Forms.Keys]::Enter) -or
                    ($code -eq [System.Windows.Forms.Keys]::Space)
        $delta = 0
        if ($code -eq [System.Windows.Forms.Keys]::Down) { $delta = 1 }
        elseif ($code -eq [System.Windows.Forms.Keys]::Up) { $delta = -1 }
        elseif ($code -eq [System.Windows.Forms.Keys]::Enter) { $delta = 1 }
        if (($delta -eq 0) -and (-not $isToggle)) { return }
        $cur = $sender.CurrentCell
        $ri = -1
        if ($cur) { $ri = $cur.RowIndex }
        if ($ri -lt 0) { $ri = 0 }
        if ($isToggle) {
            if ($ri -ge 0 -and $ri -lt $sender.Rows.Count) {
                # Discard any pending checkbox edit so keyboard toggle applies once.
                try { $sender.CancelEdit() } catch { }
                $drv = $sender.Rows[$ri].DataBoundItem
                if ($drv) {
                    $drv['Keep'] = -not [bool]$drv['Keep']
                    try { $sender.CommitEdit([System.Windows.Forms.DataGridViewDataErrorContexts]::Commit) } catch { }
                    Update-ProgramsCount
                    $sender.InvalidateRow($ri)
                }
            }
        } else {
            try { $sender.CancelEdit() } catch { }
        }
        if ($delta -ne 0) {
            $next = $ri + $delta
            if ($next -lt 0) { $next = 0 }
            if ($next -ge $sender.Rows.Count) { $next = $sender.Rows.Count - 1 }
            # Skip the new-row placeholder if it ever appears.
            while (($next -ge 0) -and ($next -lt $sender.Rows.Count) -and $sender.Rows[$next].IsNewRow) {
                $next -= [math]::Sign($delta)
            }
            if (($next -ge 0) -and ($next -lt $sender.Rows.Count)) {
                $sender.CurrentCell = $sender.Rows[$next].Cells['Keep']
                Set-ProgramsVisibleRow $sender $next
            }
        } else {
            # Space: stay on the row but make sure it is visible.
            Set-ProgramsVisibleRow $sender $ri
        }
        $e.Handled = $true
        $e.SuppressKeyPress = $true
    })

    $grid.Add_CurrentCellDirtyStateChanged({
        param($sender, $e)
        if ($sender.IsCurrentCellDirty) { [void]$sender.CommitEdit('Commit') }
    })
    $grid.Add_CellValueChanged({ Update-ProgramsCount })
    # Safety net: whatever moves the current row (mouse, default keys,
    # our KeyDown), keep it visible so the list always scrolls along.
    $grid.Add_SelectionChanged({
        param($sender, $e)
        try {
            if ($sender.CurrentCell) { Set-ProgramsVisibleRow $sender $sender.CurrentCell.RowIndex }
        } catch { }
    })
    Update-ProgramsCount
    try {
        if ($grid.Rows.Count -gt 0 -and $grid.Columns.Contains('Keep')) {
            $grid.CurrentCell = $grid.Rows[0].Cells['Keep']
        }
    } catch { }

    # ---- Bottom actions ----
    $row = New-ButtonRow 348 880
    $row.Anchor = 'Bottom, Left, Right'
    $row.TabStop = $false
    $row.TabIndex = 2
    $tab.Controls.Add($row)

    $btnAll = New-StyledButton 'Check all' 140
    $btnAll.TabIndex = 3
    $btnAll.Add_Click({
        foreach ($r in $script:ProgramsTable.Rows) { $r['Keep'] = $true }
        Update-ProgramsCount
    })
    $row.Controls.Add($btnAll)

    $btnNone = New-StyledButton 'Uncheck all' 140
    $btnNone.TabIndex = 4
    $btnNone.Add_Click({
        foreach ($r in $script:ProgramsTable.Rows) { $r['Keep'] = $false }
        Update-ProgramsCount
    })
    $row.Controls.Add($btnNone)

    $btnSave = New-StyledButton 'Save selection' 140 -Primary
    $btnSave.TabIndex = 5
    $btnSave.Add_Click({ Save-ProgramsSelection })
    $row.Controls.Add($btnSave)
    Add-Tip $btnSave 'Writes checked rows to selection.json and selection.csv (Ctrl+S)'

    $btnDiff = New-StyledButton 'Compare...' 140
    $btnDiff.TabIndex = 6
    $btnDiff.Add_Click({ Compare-Inventories })
    $row.Controls.Add($btnDiff)
    Add-Tip $btnDiff 'Diff current programs against a selection.csv from another inventory'

    $note = New-OutputNote ''
    $note.Location = New-Object System.Drawing.Point(12, 398)
    $note.Anchor = 'Bottom, Left, Right'
    $tab.Controls.Add($note)
    return $tab
}

function Update-ProgramsCount {
    $total = $script:ProgramsTable.Rows.Count
    $kept = @($script:ProgramsTable.Rows | Where-Object { $_['Keep'] -eq $true }).Count
    $text = "$kept of $total selected"
    $filter = $script:ProgramsTable.DefaultView.RowFilter
    if (-not [string]::IsNullOrWhiteSpace($filter)) {
        $text += " (" + $script:ProgramsTable.DefaultView.Count + " shown)"
    }
    $script:ProgramsCountLabel.Text = $text
}

# Keeps keyboard navigation visible: scrolls the grid so $index is shown.
# Setting CurrentCell alone does not always scroll on the last visible row.
function Set-ProgramsVisibleRow($grid, [int]$index) {
    try {
        if ($index -lt 0 -or $index -ge $grid.Rows.Count) { return }
        $displayed = $grid.DisplayedRowCount($false)
        if ($displayed -le 0) { return }
        $first = $grid.FirstDisplayedScrollingRowIndex
        if ($index -lt $first) {
            $grid.FirstDisplayedScrollingRowIndex = $index
        } elseif ($index -ge ($first + $displayed)) {
            $grid.FirstDisplayedScrollingRowIndex = $index - $displayed + 1
        }
    } catch { }
}

# Single place that writes selection.json/selection.csv from checked rows.
# Used by the Save button and by Ctrl+S in search/grid.
function Save-ProgramsSelection {
    $sel = @($script:ProgramsTable.Rows | Where-Object { $_['Keep'] -eq $true } | ForEach-Object {
        [pscustomobject]@{ Program = $_['Program']; Version = $_['Version']; Publisher = $_['Publisher'] }
    })
    # -InputObject keeps it a JSON array even with 0 or 1 items.
    ConvertTo-Json -InputObject @($sel) -Depth 3 | Out-File (Join-Path $script:OutDir 'selection.json') -Encoding UTF8
    $sel | Export-Csv (Join-Path $script:OutDir 'selection.csv') -NoTypeInformation -Encoding UTF8
    Set-Status "Selection saved: $($sel.Count) programs." -Kind Success
    [void][System.Windows.Forms.MessageBox]::Show("Selection saved ($($sel.Count) programs).", 'WipeReady')
}

# Diffs installed programs against another inventory's selection.csv.
function Compare-Inventories {
    try {
        $dlg = New-Object System.Windows.Forms.OpenFileDialog
        $dlg.Title = 'Pick a selection.csv from another inventory'
        $dlg.Filter = 'CSV files (*.csv)|*.csv'
        if ($dlg.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }
        $other = @(Import-Csv $dlg.FileName | ForEach-Object { $_.Program })
        $current = @($script:ProgramsTable.Rows | ForEach-Object { $_['Program'] })
        $added = @($current | Where-Object { $other -notcontains $_ } | Sort-Object)
        $removed = @($other | Where-Object { $current -notcontains $_ } | Sort-Object)
        $out = @()
        $out += "Only here ($($added.Count)):"
        $out += $added
        $out += ''
        $out += "Only there ($($removed.Count)):"
        $out += $removed
        $f = New-Object System.Windows.Forms.Form
        $f.Text = 'Inventory diff'
        $f.Size = New-Object System.Drawing.Size(520, 420)
        $f.StartPosition = 'CenterParent'
        $f.BackColor = $T.Bg
        $f.ForeColor = $T.Text
        $f.Font = $FontUI
        $t = New-Object System.Windows.Forms.TextBox
        $t.Multiline = $true
        $t.ReadOnly = $true
        $t.ScrollBars = 'Both'
        $t.Font = $FontMono
        $t.BackColor = $T.Bg
        $t.ForeColor = $T.Text
        $t.Dock = 'Fill'
        $t.Lines = $out
        $f.Controls.Add($t)
        [void]$f.ShowDialog($script:form)
        Set-Status 'Inventories compared.' -Kind Success
    } catch {
        Set-Status 'Compare failed.' -Kind Error
        [void][System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'WipeReady')
    }
}
