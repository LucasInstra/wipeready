# InventarioPC v1.1.0 - inventário pré-formatação com interface gráfica
# Uso (no PC que será formatado): duplo clique em InventarioPC.exe
# ou: powershell -ExecutionPolicy Bypass -File InventarioPC.ps1 (como admin)

#Requires -Version 5.1

$script:Version = '1.1.0'

# --- eleva para admin sozinho ---
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) {
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$script:OutDir = Join-Path ([Environment]::GetFolderPath('Desktop')) 'inventario-pc'
New-Item -ItemType Directory -Force -Path $script:OutDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $script:OutDir 'wifi') | Out-Null

# ================= Tema =================
$T = @{
    Bg      = [System.Drawing.ColorTranslator]::FromHtml('#0f172a')
    Panel   = [System.Drawing.ColorTranslator]::FromHtml('#1e293b')
    Accent  = [System.Drawing.ColorTranslator]::FromHtml('#38bdf8')
    Hover   = [System.Drawing.ColorTranslator]::FromHtml('#2b4a67')
    Text    = [System.Drawing.ColorTranslator]::FromHtml('#e2e8f0')
    Muted   = [System.Drawing.ColorTranslator]::FromHtml('#94a3b8')
    GridAlt = [System.Drawing.ColorTranslator]::FromHtml('#16213a')
}
$FontUI     = New-Object System.Drawing.Font('Segoe UI', 9)
$FontTitle  = New-Object System.Drawing.Font('Segoe UI', 15, [System.Drawing.FontStyle]::Bold)
$FontMono   = New-Object System.Drawing.Font('Consolas', 10)

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

function Set-Status([string]$msg) { $statusLabel.Text = $msg; $form.Refresh() }

# ================= Coleta =================
function Get-HardwareSummary {
    $cs  = Get-CimInstance Win32_ComputerSystem
    $os  = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $gpu = (Get-CimInstance Win32_VideoController | Select-Object -First 1).Name
    $key = (Get-CimInstance SoftwareLicensingService).OA3xOriginalProductKey
    if (-not $key) { $key = '(nao gravada no firmware)' }
    return [ordered]@{
        'Maquina'   = "$($cs.Manufacturer) $($cs.Model)"
        'CPU'       = $cpu.Name
        'RAM (GB)'  = [math]::Round($cs.TotalPhysicalMemory / 1GB)
        'GPU'       = $gpu
        'Sistema'   = "$($os.Caption) ($($os.Version))"
        'Instalado' = $os.InstallDate
        'Chave'     = $key
    }
}

function Get-InstalledPrograms {
    $paths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    Get-ItemProperty -Path $paths -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName } |
        Select-Object DisplayName, DisplayVersion, Publisher,
            @{N='MB'; E={ if ($_.EstimatedSize) { [math]::Round($_.EstimatedSize / 1KB) } else { $null } } } |
        Sort-Object DisplayName -Unique
}

function Get-UserFolderSizes {
    Get-ChildItem $env:USERPROFILE -Directory | ForEach-Object {
        $sum = (Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue |
            Measure-Object Length -Sum).Sum
        [pscustomobject]@{ Pasta = $_.Name; GB = [math]::Round($sum / 1GB, 2) }
    } | Sort-Object GB -Descending
}

# ================= Janela =================
$form = New-Object System.Windows.Forms.Form
$form.Text = "InventarioPC v$script:Version"
$form.Size = New-Object System.Drawing.Size(940, 640)
$form.MinimumSize = New-Object System.Drawing.Size(940, 640)
$form.StartPosition = 'CenterScreen'
$form.BackColor = $T.Bg
$form.ForeColor = $T.Text
$form.Font = $FontUI

# Cabecalho
$header = New-Object System.Windows.Forms.Panel
$header.Location = New-Object System.Drawing.Point(0, 0)
$header.Size = New-Object System.Drawing.Size(924, 66)
$header.Anchor = 'Top, Left, Right'
$header.BackColor = $T.Panel
$form.Controls.Add($header)

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = 'InventarioPC'
$lblTitle.Font = $FontTitle
$lblTitle.ForeColor = $T.Accent
$lblTitle.AutoSize = $true
$lblTitle.Location = New-Object System.Drawing.Point(16, 8)
$header.Controls.Add($lblTitle)

$lblSub = New-Object System.Windows.Forms.Label
$lblSub.Text = "Inventario pre-formatacao  •  v$script:Version  •  selecione o que manter antes de formatar"
$lblSub.Font = $FontUI
$lblSub.ForeColor = $T.Muted
$lblSub.AutoSize = $true
$lblSub.Location = New-Object System.Drawing.Point(18, 38)
$header.Controls.Add($lblSub)

$strip = New-Object System.Windows.Forms.Panel
$strip.Location = New-Object System.Drawing.Point(0, 66)
$strip.Size = New-Object System.Drawing.Size(924, 4)
$strip.Anchor = 'Top, Left, Right'
$strip.BackColor = $T.Accent
$form.Controls.Add($strip)

# Abas com desenho proprio (owner-draw)
$tabs = New-Object System.Windows.Forms.TabControl
$tabs.Location = New-Object System.Drawing.Point(10, 78)
$tabs.Size = New-Object System.Drawing.Size(904, 478)
$tabs.Anchor = 'Top, Bottom, Left, Right'
$tabs.DrawMode = 'OwnerDrawFixed'
$tabs.SizeMode = 'Fixed'
$tabs.ItemSize = New-Object System.Drawing.Size(170, 34)
$tabs.Font = $FontUI
$form.Controls.Add($tabs)

$tabs.Add_DrawItem({
    param($s, $e)
    $selected = ($e.Index -eq $s.SelectedIndex)
    $bg = if ($selected) { $T.Accent } else { $T.Panel }
    $fg = if ($selected) { $T.Bg } else { $T.Text }
    $brush = New-Object System.Drawing.SolidBrush($bg)
    $e.Graphics.FillRectangle($brush, $e.Bounds)
    $brush.Dispose()
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = 'Center'
    $sf.LineAlignment = 'Center'
    $fnt = if ($selected) {
        New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)
    } else { $FontUI }
    $e.Graphics.DrawString($s.TabPages[$e.Index].Text, $fnt,
        (New-Object System.Drawing.SolidBrush($fg)), $e.Bounds, $sf)
    $sf.Dispose()
    if ($selected) { $fnt.Dispose() }
})

$status = New-Object System.Windows.Forms.StatusStrip
$status.BackColor = $T.Panel
$status.ForeColor = $T.Text
$statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLabel.Text = 'Pronto.'
$statusLabel.ForeColor = $T.Text
$status.Items.Add($statusLabel) | Out-Null
$form.Controls.Add($status)

# ================= Aba Resumo =================
$tabResumo = New-Object System.Windows.Forms.TabPage
$tabResumo.Text = 'Resumo'
$tabResumo.BackColor = $T.Bg
$tabResumo.Padding = New-Object System.Windows.Forms.Padding(12)
$tabs.TabPages.Add($tabResumo) | Out-Null

$txtResumo = New-Object System.Windows.Forms.TextBox
$txtResumo.Multiline = $true
$txtResumo.ReadOnly = $true
$txtResumo.ScrollBars = 'Vertical'
$txtResumo.Font = $FontMono
$txtResumo.BackColor = $T.Bg
$txtResumo.ForeColor = $T.Text
$txtResumo.BorderStyle = 'FixedSingle'
$txtResumo.Dock = 'Top'
$txtResumo.Height = 300
$tabResumo.Controls.Add($txtResumo)

$hw = Get-HardwareSummary
$txtResumo.Lines = $hw.GetEnumerator() | ForEach-Object { "$($_.Key): $($_.Value)" }

$btnDrivers = New-StyledButton 'Exportar drivers' 12 322
$btnDrivers.Add_Click({
    try {
        Set-Status 'Exportando drivers... (pode demorar)'
        Export-WindowsDriver -Online -Destination (Join-Path $script:OutDir 'drivers') | Out-Null
        Set-Status 'Drivers exportados para inventario-pc\drivers.'
    } catch {
        Set-Status 'Falha ao exportar drivers.'
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'InventarioPC')
    }
})
$tabResumo.Controls.Add($btnDrivers)

$btnWifi = New-StyledButton 'Exportar Wi-Fi' 194 322
$btnWifi.Add_Click({
    $w = Join-Path $script:OutDir 'wifi'
    netsh wlan export profile folder="$w" key=clear | Out-Null
    Set-Status 'Perfis Wi-Fi exportados para inventario-pc\wifi.'
})
$tabResumo.Controls.Add($btnWifi)

$btnHtml = New-StyledButton 'Relatorio HTML' 376 322
$btnHtml.Add_Click({
    Set-Status 'Gerando relatorio...'
    $css = '<style>body{font-family:"Segoe UI";background:#0f172a;color:#e2e8f0;padding:24px}h2{color:#38bdf8;border-bottom:1px solid #334155}table{border-collapse:collapse;width:100%;margin-bottom:24px}th{background:#1e293b;text-align:left;padding:6px}td{border-bottom:1px solid #1e293b;padding:6px;font-size:13px}.card{background:#1e293b;padding:12px;border-radius:8px;margin-bottom:16px}</style>'
    $progs = Get-InstalledPrograms
    $pastas = Get-UserFolderSizes
    $startup = Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, User
    $info = Get-HardwareSummary
    $html = "<html><head><meta charset='utf-8'>$css</head><body><h1>Inventario do PC</h1>"
    $html += "<div class='card'>" + (($info.GetEnumerator() | ForEach-Object { "<b>$($_.Key):</b> $($_.Value)" }) -join '<br>') + '</div>'
    $html += '<h2>Programas</h2>' + ($progs | ConvertTo-Html -Fragment)
    $html += '<h2>Pastas (GB)</h2>' + ($pastas | ConvertTo-Html -Fragment)
    $html += '<h2>Inicializacao</h2>' + ($startup | ConvertTo-Html -Fragment)
    $html += '</body></html>'
    $html | Out-File (Join-Path $script:OutDir 'relatorio.html') -Encoding UTF8
    Set-Status 'Relatorio gerado e aberto no navegador.'
    Invoke-Item (Join-Path $script:OutDir 'relatorio.html')
})
$tabResumo.Controls.Add($btnHtml)

# ================= Aba Programas =================
$tabProgs = New-Object System.Windows.Forms.TabPage
$tabProgs.Text = 'Programas'
$tabProgs.BackColor = $T.Bg
$tabProgs.Padding = New-Object System.Windows.Forms.Padding(12)
$tabs.TabPages.Add($tabProgs) | Out-Null

$grid = New-Object System.Windows.Forms.DataGridView
$grid.Dock = 'Top'
$grid.Height = 340
$tabProgs.Controls.Add($grid)

$script:dt = New-Object System.Data.DataTable
[void]$script:dt.Columns.Add('Manter', [bool])
[void]$script:dt.Columns.Add('Programa', [string])
[void]$script:dt.Columns.Add('Versao', [string])
[void]$script:dt.Columns.Add('Editor', [string])
foreach ($p in (Get-InstalledPrograms)) {
    $row = $script:dt.NewRow()
    $row['Manter'] = $true
    $row['Programa'] = $p.DisplayName
    $row['Versao'] = $p.DisplayVersion
    $row['Editor'] = $p.Publisher
    $script:dt.Rows.Add($row)
}
$grid.DataSource = $script:dt
$grid.Columns['Manter'].ReadOnly = $false
$grid.Columns['Programa'].ReadOnly = $true
$grid.Columns['Versao'].ReadOnly = $true
$grid.Columns['Editor'].ReadOnly = $true
Style-Grid $grid

$btnTodos = New-StyledButton 'Marcar todos' 12 366 140
$btnTodos.Add_Click({ foreach ($r in $script:dt.Rows) { $r['Manter'] = $true } })
$tabProgs.Controls.Add($btnTodos)

$btnNenhum = New-StyledButton 'Desmarcar todos' 160 366 140
$btnNenhum.Add_Click({ foreach ($r in $script:dt.Rows) { $r['Manter'] = $false } })
$tabProgs.Controls.Add($btnNenhum)

$btnSalvar = New-StyledButton 'Salvar selecao' 308 366 140
$btnSalvar.Add_Click({
    $sel = @($script:dt.Rows | Where-Object { $_['Manter'] -eq $true } | ForEach-Object {
        [pscustomobject]@{ Programa = $_['Programa']; Versao = $_['Versao']; Editor = $_['Editor'] }
    })
    $sel | ConvertTo-Json -Depth 3 | Out-File (Join-Path $script:OutDir 'selecao.json') -Encoding UTF8
    $sel | Export-Csv (Join-Path $script:OutDir 'selecao.csv') -NoTypeInformation -Encoding UTF8
    Set-Status "Selecao salva: $($sel.Count) programas."
    [System.Windows.Forms.MessageBox]::Show("Selecao salva ($($sel.Count) programas).", 'InventarioPC')
})
$tabProgs.Controls.Add($btnSalvar)

# ================= Aba Pastas & Backup =================
$tabPastas = New-Object System.Windows.Forms.TabPage
$tabPastas.Text = 'Pastas e Backup'
$tabPastas.BackColor = $T.Bg
$tabPastas.Padding = New-Object System.Windows.Forms.Padding(12)
$tabs.TabPages.Add($tabPastas) | Out-Null

$lstPastas = New-Object System.Windows.Forms.ListView
$lstPastas.View = 'Details'
$lstPastas.FullRowSelect = $true
$lstPastas.Dock = 'Top'
$lstPastas.Height = 300
$lstPastas.BackColor = $T.Bg
$lstPastas.ForeColor = $T.Text
$lstPastas.BorderStyle = 'None'
$lstPastas.Font = $FontUI
[void]$lstPastas.Columns.Add('Pasta', 320)
[void]$lstPastas.Columns.Add('GB', 120)
$tabPastas.Controls.Add($lstPastas)

$btnEscanear = New-StyledButton 'Escanear pastas' 12 326
$btnEscanear.Add_Click({
    Set-Status 'Escaneando pastas... (pode demorar conforme o volume de arquivos)'
    $form.Refresh()
    $lstPastas.Items.Clear()
    foreach ($f in (Get-UserFolderSizes)) {
        $item = New-Object System.Windows.Forms.ListViewItem($f.Pasta)
        [void]$item.SubItems.Add("$($f.GB)")
        $lstPastas.Items.Add($item) | Out-Null
    }
    Set-Status 'Escaneamento concluido.'
})
$tabPastas.Controls.Add($btnEscanear)

$tabPastas.Controls.Add((New-SectionLabel 'Copie para o HD externo: Desktop, Documentos, Imagens, Downloads, saves de jogos e a pasta inventario-pc.' 196 326 660))

# ================= Aba Pos-formatacao =================
$tabPos = New-Object System.Windows.Forms.TabPage
$tabPos.Text = 'Pos-formatacao'
$tabPos.BackColor = $T.Bg
$tabPos.Padding = New-Object System.Windows.Forms.Padding(12)
$tabs.TabPages.Add($tabPos) | Out-Null

$txtPos = New-Object System.Windows.Forms.TextBox
$txtPos.Multiline = $true
$txtPos.ReadOnly = $true
$txtPos.ScrollBars = 'Vertical'
$txtPos.Font = $FontMono
$txtPos.BackColor = $T.Bg
$txtPos.ForeColor = $T.Text
$txtPos.BorderStyle = 'FixedSingle'
$txtPos.Dock = 'Top'
$txtPos.Height = 300
$txtPos.Text = "1. Instale o Windows da ISO.`r`n2. Rode: winget import -i reinstalar.json`r`n3. Reinstale o resto pela selecao.csv.`r`n4. Confira drivers e Wi-Fi salvos."
$tabPos.Controls.Add($txtPos)

$btnWinget = New-StyledButton 'Exportar winget' 12 322
$btnWinget.Add_Click({
    try {
        Set-Status 'Exportando lista do winget...'
        winget export -o (Join-Path $script:OutDir 'reinstalar.json') --include-versions
        Set-Status 'reinstalar.json criado. Depois de formatar: winget import -i reinstalar.json'
    } catch {
        Set-Status 'Falha ao exportar winget.'
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'InventarioPC')
    }
})
$tabPos.Controls.Add($btnWinget)

$btnAbrir = New-StyledButton 'Abrir pasta' 194 322
$btnAbrir.Add_Click({ Invoke-Item $script:OutDir })
$tabPos.Controls.Add($btnAbrir)

[void]$form.ShowDialog()
