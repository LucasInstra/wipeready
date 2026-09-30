# WipeReady "Programs" tab: checklist of installed programs to keep

function Add-ProgramsTab {
    $tab = New-Object System.Windows.Forms.TabPage
    $tab.Text = 'Programs'
    $tab.BackColor = $T.Bg
    $tab.Padding = New-Object System.Windows.Forms.Padding(12)
    $script:tabs.TabPages.Add($tab) | Out-Null

    $grid = New-Object System.Windows.Forms.DataGridView
    $grid.Dock = 'Top'
    $grid.Height = 340
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
        $script:ProgramsTable.Rows.Add($row)
    }
    $grid.DataSource = $script:ProgramsTable
    $grid.Columns['Keep'].ReadOnly = $false
    $grid.Columns['Program'].ReadOnly = $true
    $grid.Columns['Version'].ReadOnly = $true
    $grid.Columns['Publisher'].ReadOnly = $true
    Style-Grid $grid

    $btnAll = New-StyledButton 'Check all' 12 366 140
    $btnAll.Add_Click({ foreach ($r in $script:ProgramsTable.Rows) { $r['Keep'] = $true } })
    $tab.Controls.Add($btnAll)

    $btnNone = New-StyledButton 'Uncheck all' 160 366 140
    $btnNone.Add_Click({ foreach ($r in $script:ProgramsTable.Rows) { $r['Keep'] = $false } })
    $tab.Controls.Add($btnNone)

    $btnSave = New-StyledButton 'Save selection' 308 366 140
    $btnSave.Add_Click({
        $sel = @($script:ProgramsTable.Rows | Where-Object { $_['Keep'] -eq $true } | ForEach-Object {
            [pscustomobject]@{ Program = $_['Program']; Version = $_['Version']; Publisher = $_['Publisher'] }
        })
        $sel | ConvertTo-Json -Depth 3 | Out-File (Join-Path $script:OutDir 'selection.json') -Encoding UTF8
        $sel | Export-Csv (Join-Path $script:OutDir 'selection.csv') -NoTypeInformation -Encoding UTF8
        Set-Status "Selection saved: $($sel.Count) programs."
        [System.Windows.Forms.MessageBox]::Show("Selection saved ($($sel.Count) programs).", 'WipeReady')
    })
    $tab.Controls.Add($btnSave)
}
