# WipeReady theme (dark) + shared UI helpers
# Presentation only: colors, fonts, control factories. No data collection here.

$T = @{
    Bg        = [System.Drawing.ColorTranslator]::FromHtml('#0f172a')
    Panel     = [System.Drawing.ColorTranslator]::FromHtml('#1e293b')
    Accent    = [System.Drawing.ColorTranslator]::FromHtml('#38bdf8')
    AccentDark= [System.Drawing.ColorTranslator]::FromHtml('#0284c7')
    Hover     = [System.Drawing.ColorTranslator]::FromHtml('#2b4a67')
    Text      = [System.Drawing.ColorTranslator]::FromHtml('#e2e8f0')
    Muted     = [System.Drawing.ColorTranslator]::FromHtml('#94a3b8')
    GridAlt   = [System.Drawing.ColorTranslator]::FromHtml('#16213a')
    Success   = [System.Drawing.ColorTranslator]::FromHtml('#4ade80')
    Warn      = [System.Drawing.ColorTranslator]::FromHtml('#fbbf24')
    Error     = [System.Drawing.ColorTranslator]::FromHtml('#f87171')
}
$FontUI      = New-Object System.Drawing.Font('Segoe UI', 9)
$FontTitle   = New-Object System.Drawing.Font('Segoe UI', 15, [System.Drawing.FontStyle]::Bold)
$FontSection = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Bold)
$FontMono    = New-Object System.Drawing.Font('Consolas', 10)

# Standard button. Place inside a button-row panel (flow layout).
function New-StyledButton([string]$text, [int]$w = 170, [switch]$Primary) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $text
    $b.Size = New-Object System.Drawing.Size($w, 34)
    $b.Margin = New-Object System.Windows.Forms.Padding(0, 0, 10, 0)
    $b.FlatStyle = 'Flat'
    $b.UseVisualStyleBackColor = $false
    $b.Font = $FontUI
    $b.Cursor = [System.Windows.Forms.Cursors]::Hand
    if ($Primary) {
        $b.BackColor = $T.Accent
        $b.ForeColor = $T.Bg
        $b.FlatAppearance.BorderColor = $T.Accent
        $b.FlatAppearance.MouseOverBackColor = $T.AccentDark
    } else {
        $b.BackColor = $T.Panel
        $b.ForeColor = $T.Text
        $b.FlatAppearance.BorderColor = $T.Accent
        $b.FlatAppearance.MouseOverBackColor = $T.Hover
    }
    $b.FlatAppearance.BorderSize = 1
    return $b
}

# Horizontal button row. Anchored by the caller; buttons wrap instead of clipping.
function New-ButtonRow([int]$y, [int]$w) {
    $f = New-Object System.Windows.Forms.FlowLayoutPanel
    $f.Location = New-Object System.Drawing.Point(12, $y)
    $f.Size = New-Object System.Drawing.Size($w, 44)
    $f.Anchor = 'Bottom, Left, Right'
    $f.BackColor = $T.Bg
    $f.FlowDirection = 'LeftToRight'
    $f.WrapContents = $true
    return $f
}

# Section header bar: title + one-line description. Stretches with the tab.
function New-SectionHeader([string]$title, [string]$desc) {
    # NOTE: locals must not be named $t/$T (PowerShell is case-insensitive).
    $pnlH = New-Object System.Windows.Forms.Panel
    $pnlH.Location = New-Object System.Drawing.Point(12, 8)
    $pnlH.Size = New-Object System.Drawing.Size(880, 58)
    $pnlH.Anchor = 'Top, Left, Right'
    $pnlH.BackColor = $T.Bg
    $lblTitleH = New-Object System.Windows.Forms.Label
    $lblTitleH.Text = $title
    $lblTitleH.Font = $FontSection
    $lblTitleH.ForeColor = $T.Text
    $lblTitleH.Location = New-Object System.Drawing.Point(0, 0)
    $lblTitleH.AutoSize = $true
    $pnlH.Controls.Add($lblTitleH)
    $lblDescH = New-Object System.Windows.Forms.Label
    $lblDescH.Text = $desc
    $lblDescH.Font = $FontUI
    $lblDescH.ForeColor = $T.Muted
    $lblDescH.Location = New-Object System.Drawing.Point(0, 30)
    $lblDescH.Size = New-Object System.Drawing.Size(880, 22)
    $lblDescH.Anchor = 'Top, Left, Right'
    $pnlH.Controls.Add($lblDescH)
    return $pnlH
}

# Surface card. Caller sets Location/Size/Anchor; content is added by the caller.
function New-Card {
    $c = New-Object System.Windows.Forms.Panel
    $c.BackColor = $T.Panel
    $c.Padding = New-Object System.Windows.Forms.Padding(14)
    return $c
}

function New-CardTitle([string]$text) {
    $l = New-Object System.Windows.Forms.Label
    $l.Text = $text
    $l.Font = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
    $l.ForeColor = $T.Accent
    $l.AutoSize = $true
    return $l
}

function New-OutputNote([string]$subpath) {
    $l = New-Object System.Windows.Forms.Label
    $l.Text = "Files are saved to Desktop\wipeready$subpath"
    $l.Font = $FontUI
    $l.ForeColor = $T.Muted
    $l.AutoSize = $true
    return $l
}

function Add-Tip($control, [string]$text) {
    $script:Tips.SetToolTip($control, $text)
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
