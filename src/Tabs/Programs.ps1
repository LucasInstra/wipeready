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
        $g = $script:ProgramsGrid
        if ($g -and $g.Rows.Count -gt 0) {
            $before = Get-ProgramsNavSnapshot $g
            try {
                $g.CurrentCell = $g.Rows[0].Cells['Keep']
                $g.FirstDisplayedScrollingRowIndex = 0
            } catch {
                Write-ProgramsNavLog -Key 'FilterReset' -Grid $g -Before $before -Exception $_.Exception.Message -Phase 'catch'
            }
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
                $before = Get-ProgramsNavSnapshot $g
                $navError = ''
                try {
                    $g.Focus()
                    $ri = 0
                    if ($g.CurrentCell) { $ri = $g.CurrentCell.RowIndex }
                    if ($ri -lt 0 -or $ri -ge $g.Rows.Count) { $ri = 0 }
                    $g.CurrentCell = $g.Rows[$ri].Cells['Keep']
                    Set-ProgramsVisibleRow $g $ri 'SearchDown'
                } catch {
                    $navError = $_.Exception.Message
                    Write-ProgramsNavLog -Key 'SearchDown' -Grid $g -Before $before -Exception $navError -Phase 'catch'
                } finally {
                    $e.Handled = $true
                    $e.SuppressKeyPress = $true
                    Write-ProgramsNavLog -Key 'SearchDown' -Grid $g -Before $before -Exception $navError
                }
            }
        }
    })

    # When the grid receives focus via Tab, land on the Keep checkbox
    # of the current row instead of a read-only text cell.
    $grid.Add_Enter({
        param($sender, $e)
        $before = Get-ProgramsNavSnapshot $sender
        try {
            if ($sender.Rows.Count -gt 0) {
                $ri = 0
                if ($sender.CurrentCell) { $ri = $sender.CurrentCell.RowIndex }
                if ($ri -lt 0 -or $ri -ge $sender.Rows.Count) { $ri = 0 }
                if ($sender.Columns.Contains('Keep')) {
                    $sender.CurrentCell = $sender.Rows[$ri].Cells['Keep']
                    Set-ProgramsVisibleRow $sender $ri 'GridEnter'
                }
            }
        } catch {
            Write-ProgramsNavLog -Key 'GridEnter' -Grid $sender -Before $before -Exception $_.Exception.Message -Phase 'catch'
        }
    })

    # Enter toggles + advances (checklist flow), Down/Up moves,
    # Space toggles without moving. Every move keeps the row within the
    # top 10 visible lines so the list starts scrolling early.
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
        $before = Get-ProgramsNavSnapshot $sender
        $navErrors = New-Object 'System.Collections.Generic.List[string]'
        try {
            $cur = $sender.CurrentCell
            $ri = -1
            if ($cur) { $ri = $cur.RowIndex }
            if ($ri -lt 0) { $ri = 0 }
            if ($isToggle) {
                if ($ri -ge 0 -and $ri -lt $sender.Rows.Count) {
                    # Flush (never discard): a pending checkbox edit holds the
                    # user's last change, so commit it as the baseline first.
                    try { [void]$sender.EndEdit() } catch {
                        $message = 'EndEdit: ' + $_.Exception.Message
                        [void]$navErrors.Add($message)
                        Write-ProgramsNavLog -Key $code -Grid $sender -Before $before -Exception $message -Phase 'catch'
                    }
                    $drv = $sender.Rows[$ri].DataBoundItem
                    if ($drv) {
                        $drv['Keep'] = -not [bool]$drv['Keep']
                        # Commit through EndEdit too: otherwise the toggle can
                        # sit uncommitted and a later move would drop it.
                        try { [void]$sender.EndEdit() } catch {
                            $message = 'EndEdit: ' + $_.Exception.Message
                            [void]$navErrors.Add($message)
                            Write-ProgramsNavLog -Key $code -Grid $sender -Before $before -Exception $message -Phase 'catch'
                        }
                        Update-ProgramsCount
                        $sender.InvalidateRow($ri)
                    }
                }
            } else {
                # Moving away: flush pending edits so nothing is lost/discarded.
                try { [void]$sender.EndEdit() } catch {
                    $message = 'EndEdit: ' + $_.Exception.Message
                    [void]$navErrors.Add($message)
                    Write-ProgramsNavLog -Key $code -Grid $sender -Before $before -Exception $message -Phase 'catch'
                }
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
                    Set-ProgramsVisibleRow $sender $next ([string]$code)
                }
            } else {
                # Space: stay on the row but make sure it is visible.
                Set-ProgramsVisibleRow $sender $ri ([string]$code)
            }
        } catch {
            $message = 'KeyDown: ' + $_.Exception.Message
            [void]$navErrors.Add($message)
            Write-ProgramsNavLog -Key $code -Grid $sender -Before $before -Exception $message -Phase 'catch'
        } finally {
            $e.Handled = $true
            $e.SuppressKeyPress = $true
            Write-ProgramsNavLog -Key $code -Grid $sender -Before $before -Exception ([string]::Join('; ', $navErrors.ToArray()))
        }
    })

    $grid.Add_CurrentCellDirtyStateChanged({
        param($sender, $e)
        if ($sender.IsCurrentCellDirty) { [void]$sender.CommitEdit('Commit') }
    })
    $grid.Add_CellValueChanged({ Update-ProgramsCount })
    # Do not snap CurrentCell from Scroll: DataGridView raises Scroll while
    # its own ensure-visible logic and Set-ProgramsVisibleRow are moving the
    # viewport. Key navigation plus SelectionChanged owns keyboard visibility.
    $grid.Add_SelectionChanged({
        param($sender, $e)
        $before = Get-ProgramsNavSnapshot $sender
        try {
            if ($sender.CurrentCell) {
                Set-ProgramsVisibleRow $sender $sender.CurrentCell.RowIndex 'SelectionChanged'
            }
        } catch {
            Write-ProgramsNavLog -Key 'SelectionChanged' -Grid $sender -Before $before -Exception $_.Exception.Message -Phase 'catch'
        }
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

    # Silent auto-save when the app closes so the checklist is never lost.
    $script:form.Add_FormClosing({
        try {
            if ($script:ProgramsTable -and $script:ProgramsTable.Rows.Count -gt 0) {
                [void](Write-ProgramsSelection)
            }
        } catch { }
    })

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

# Keeps keyboard navigation visible: scrolling starts once the current
# row passes the 10th visible line (never near the bottom edge unseen).
function Set-ProgramsVisibleRow($grid, [int]$index, [string]$key = 'SetVisibleRow') {
    $before = Get-ProgramsNavSnapshot $grid
    try {
        if ($index -lt 0 -or $index -ge $grid.Rows.Count) { return }
        $displayed = $grid.DisplayedRowCount($false)
        if ($displayed -le 0) { return }
        if ($displayed -ge $grid.Rows.Count) { return } # everything fits
        $first = $grid.FirstDisplayedScrollingRowIndex
        if ($index -le $first) {
            if ($first -ne $index) { $grid.FirstDisplayedScrollingRowIndex = $index }
        } else {
            # 10th visible line (0-based 9); smaller grids fall back to
            # keeping one row of context below the current row.
            $marginTop = [math]::Min(9, $displayed - 1)
            $wantFirst = $index - $marginTop
            if ($wantFirst -lt 0) { $wantFirst = 0 }
            $maxFirst = $grid.Rows.Count - $displayed
            if ($wantFirst -gt $maxFirst) { $wantFirst = $maxFirst }
            if ($wantFirst -gt $first) {
                $grid.FirstDisplayedScrollingRowIndex = $wantFirst
            } elseif ($index -ge ($first + $displayed)) {
                # Below the viewport entirely (shouldn't happen): snap minimally.
                $snap = $index - $displayed + 1
                if ($snap -lt 0) { $snap = 0 }
                if ($snap -gt $maxFirst) { $snap = $maxFirst }
                $grid.FirstDisplayedScrollingRowIndex = $snap
            }
        }
    } catch {
        Write-ProgramsNavLog -Key $key -Grid $grid -Before $before -Exception $_.Exception.Message -Phase 'scroll-catch'
    }
}

function Get-ProgramsNavSnapshot($grid) {
    $cell = '-'
    try {
        if ($grid.CurrentCell) {
            $column = ''
            if ($grid.CurrentCell.OwningColumn) { $column = $grid.CurrentCell.OwningColumn.Name }
            $cell = '{0}:{1}' -f $grid.CurrentCell.RowIndex, $column
        }
    } catch { }
    $first = -1
    try { $first = $grid.FirstDisplayedScrollingRowIndex } catch { }
    $displayed = -1
    try { $displayed = $grid.DisplayedRowCount($false) } catch { }
    $rows = -1
    try { $rows = $grid.Rows.Count } catch { }
    $focus = 'none'
    try {
        $form = $grid.FindForm()
        $active = $form
        while ($active -and $active.Controls.Count -gt 0) {
            $focusedChild = $null
            foreach ($candidate in $active.Controls) {
                if ($candidate.Focused -or $candidate.ContainsFocus) {
                    $focusedChild = $candidate
                    break
                }
            }
            if (-not $focusedChild) { break }
            $active = $focusedChild
        }
        if ($active) { $focus = $active.GetType().Name }
        elseif ($grid.Focused -or $grid.ContainsFocus) { $focus = $grid.GetType().Name }
    } catch { }
    return [pscustomobject]@{
        Cell = $cell
        First = $first
        Displayed = $displayed
        Rows = $rows
        Focus = $focus
    }
}

function Write-ProgramsNavLog {
    param(
        [string]$Key,
        $Grid,
        $Before,
        [string]$Exception = '',
        [string]$Phase = 'nav'
    )
    try {
        if (-not $Before) { $Before = Get-ProgramsNavSnapshot $Grid }
        $after = Get-ProgramsNavSnapshot $Grid
        $keyText = $Key -replace '[\r\n|]', ' '
        if ($keyText -eq 'Return') { $keyText = 'Enter' }
        $exceptionText = $Exception -replace '[\r\n|]', ' '
        if ([string]::IsNullOrWhiteSpace($exceptionText)) { $exceptionText = '-' }
        $line = '{0:yyyy-MM-ddTHH:mm:ss.fff} key={1} phase={2} CurrentCell={3}->{4} FirstDisplayed={5}->{6} DisplayedRowCount={7}->{8} Rows={9}->{10} FocusedControl={11}->{12} Exception={13}' -f `
            [DateTime]::Now, $keyText, $Phase, $Before.Cell, $after.Cell, $Before.First, $after.First, `
            $Before.Displayed, $after.Displayed, $Before.Rows, $after.Rows, $Before.Focus, $after.Focus, $exceptionText
        $path = Join-Path $env:TEMP 'wipeready-nav.log'
        [System.IO.File]::AppendAllText($path, $line + [Environment]::NewLine, [System.Text.Encoding]::UTF8)
    } catch { }
}

# Single place that writes selection.json/selection.csv from checked rows.
# Returns the number of saved programs. Used by the Save button, Ctrl+S
# and the silent auto-save on app close.
function Write-ProgramsSelection {
    $sel = @($script:ProgramsTable.Rows | Where-Object { $_['Keep'] -eq $true } | ForEach-Object {
        [pscustomobject]@{ Program = $_['Program']; Version = $_['Version']; Publisher = $_['Publisher'] }
    })
    # -InputObject keeps it a JSON array even with 0 or 1 items.
    ConvertTo-Json -InputObject @($sel) -Depth 3 | Out-File (Join-Path $script:OutDir 'selection.json') -Encoding UTF8
    $sel | Export-Csv (Join-Path $script:OutDir 'selection.csv') -NoTypeInformation -Encoding UTF8
    return @($sel).Count
}

function Save-ProgramsSelection {
    $count = Write-ProgramsSelection
    Set-Status "Selection saved: $count programs." -Kind Success
    [void][System.Windows.Forms.MessageBox]::Show("Selection saved ($count programs).", 'WipeReady')
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
