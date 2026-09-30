# WipeReady theme (dark) + shared UI helpers

$T = @{
    Bg      = [System.Drawing.ColorTranslator]::FromHtml('#0f172a')
    Panel   = [System.Drawing.ColorTranslator]::FromHtml('#1e293b')
    Accent  = [System.Drawing.ColorTranslator]::FromHtml('#38bdf8')
    Hover   = [System.Drawing.ColorTranslator]::FromHtml('#2b4a67')
    Text    = [System.Drawing.ColorTranslator]::FromHtml('#e2e8f0')
    Muted   = [System.Drawing.ColorTranslator]::FromHtml('#94a3b8')
    GridAlt = [System.Drawing.ColorTranslator]::FromHtml('#16213a')
}
$FontUI    = New-Object System.Drawing.Font('Segoe UI', 9)
$FontTitle = New-Object System.Drawing.Font('Segoe UI', 15, [System.Drawing.FontStyle]::Bold)
$FontMono  = New-Object System.Drawing.Font('Consolas', 10)

function New-StyledButton([string]$text, [int]$x, [int]$y, [int]$w = 170) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $text
    $b.Size = New-Object System.Drawing.Size($w, 34)
    $b.Location = New-Object System.Drawing.Point($x, $y)
    $b.FlatStyle = 'Flat'
    $b.UseVisualStyleBackColor = $false
    $b.BackColor = $T.Panel
    $b.ForeColor = $T.Text
    $b.Font = $FontUI
    $b.FlatAppearance.BorderColor = $T.Accent
    $b.FlatAppearance.BorderSize = 1
    $b.FlatAppearance.MouseOverBackColor = $T.Hover
    $b.Cursor = [System.Windows.Forms.Cursors]::Hand
    return $b
}

function New-SectionLabel([string]$text, [int]$x, [int]$y, [int]$w) {
    $l = New-Object System.Windows.Forms.Label
    $l.Text = $text
    $l.AutoSize = $false
    $l.Size = New-Object System.Drawing.Size($w, 40)
    $l.Location = New-Object System.Drawing.Point($x, $y)
    $l.ForeColor = $T.Muted
    $l.Font = $FontUI
    return $l
}

function Style-Grid([System.Windows.Forms.DataGridView]$g) {
    $g.EnableHeadersVisualStyles = $false
    $g.BackgroundColor = $T.Bg
    $g.BorderStyle = 'None'
    $g.GridColor = $T.Panel
    $g.RowHeadersVisible = $false
    $g.Font = $FontUI
    $g.AutoSizeColumnsMode = 'Fill'
    $g.SelectionMode = 'FullRowSelect'
    $g.AllowUserToAddRows = $false
    $g.AllowUserToDeleteRows = $false
    $g.ColumnHeadersHeight = 30
    $g.RowTemplate.Height = 26
    $g.ColumnHeadersDefaultCellStyle.BackColor = $T.Panel
    $g.ColumnHeadersDefaultCellStyle.ForeColor = $T.Accent
    $g.ColumnHeadersDefaultCellStyle.Font = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)
    $g.ColumnHeadersDefaultCellStyle.SelectionBackColor = $T.Panel
    $g.RowsDefaultCellStyle.BackColor = $T.Bg
    $g.RowsDefaultCellStyle.ForeColor = $T.Text
    $g.RowsDefaultCellStyle.SelectionBackColor = $T.Hover
    $g.AlternatingRowsDefaultCellStyle.BackColor = $T.GridAlt
    $g.AlternatingRowsDefaultCellStyle.ForeColor = $T.Text
}
