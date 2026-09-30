# InventarioPC - inventário pré-formatação com interface gráfica
# Uso (no PC pessoal, como administrador):
#   powershell -ExecutionPolicy Bypass -File InventarioPC.ps1

#Requires -Version 5.1

$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) {
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# ---------------- Tema escuro ----------------
$T = @{
    Bg      = [System.Drawing.ColorTranslator]::FromHtml('#0f172a')
    Panel   = [System.Drawing.ColorTranslator]::FromHtml('#1e293b')
    Accent  = [System.Drawing.ColorTranslator]::FromHtml('#38bdf8')
    Hover   = [System.Drawing.ColorTranslator]::FromHtml('#2b4a67')
    Text    = [System.Drawing.ColorTranslator]::FromHtml('#e2e8f0')
    GridAlt = [System.Drawing.ColorTranslator]::FromHtml('#16213a')
}
$FontUI = New-Object System.Drawing.Font('Segoe UI', 9)

function Apply-Theme([System.Windows.Forms.Control]$root) {
    foreach ($c in $root.Controls) {
        if ($c -is [System.Windows.Forms.Button]) {
            $c.FlatStyle = 'Flat'
            $c.UseVisualStyleBackColor = $false
            $c.BackColor = $T.Panel
            $c.ForeColor = $T.Text
            $c.FlatAppearance.BorderColor = $T.Accent
            $c.FlatAppearance.BorderSize = 1
            $c.FlatAppearance.MouseOverBackColor = $T.Hover
            $c.Font = $FontUI
        } elseif ($c -is [System.Windows.Forms.TextBox]) {
            $c.BackColor = $T.Bg
            $c.ForeColor = $T.Text
            $c.BorderStyle = 'FixedSingle'
        } elseif ($c -is [System.Windows.Forms.ListView]) {
            $c.BackColor = $T.Bg
            $c.ForeColor = $T.Text
            $c.BorderStyle = 'None'
            $c.Font = $FontUI
        } elseif ($c -is [System.Windows.Forms.Label]) {
            $c.ForeColor = $T.Text
            $c.Font = $FontUI
        } elseif ($c -is [System.Windows.Forms.TabPage]) {
            $c.BackColor = $T.Bg
            $c.ForeColor = $T.Text
            $c.Font = $FontUI
        } elseif ($c -is [System.Windows.Forms.StatusStrip]) {
            $c.BackColor = $T.Panel
            $c.ForeColor = $T.Text
            foreach ($item in $c.Items) { $item.ForeColor = $T.Text }
        }
        if ($c.Controls.Count -gt 0) { Apply-Theme $c }
    }
}

function Style-Grid([System.Windows.Forms.DataGridView]$g) {
    $g.EnableHeadersVisualStyles = $false
    $g.BackgroundColor = $T.Bg
    $g.BorderStyle = 'None'
    $g.GridColor = $T.Panel
    $g.RowHeadersVisible = $false
    $g.Font = $FontUI
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

$script:OutDir = Join-Path ([Environment]::GetFolderPath('Desktop')) 'inventario-pc'
New-Item -ItemType Directory -Force -Path $script:OutDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $script:OutDir 'wifi') | Out-Null

function Get-HardwareSummary {
    $cs  = Get-CimInstance Win32_ComputerSystem
    $os  = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $gpu = (Get-CimInstance Win32_VideoController | Select-Object -First 1).Name
    $key = (Get-CimInstance SoftwareLicensingService).OA3xOriginalProductKey
    if (-not $key) { $key = '(não gravada no firmware)' }
    return [ordered]@{
        'Máquina'   = "$($cs.Manufacturer) $($cs.Model)"
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

# ---------------- Janela ----------------
$form = New-Object System.Windows.Forms.Form
$form.Text = 'InventarioPC - antes de formatar'
$form.Size = New-Object System.Drawing.Size(920, 620)
$form.StartPosition = 'CenterScreen'
$form.BackColor = $T.Bg
$form.ForeColor = $T.Text
$form.Font = $FontUI

$strip = New-Object System.Windows.Forms.Panel
$strip.Dock = 'Top'
$strip.Height = 5
$strip.BackColor = $T.Accent
$form.Controls.Add($strip)

$tabs = New-Object System.Windows.Forms.TabControl
$tabs.Dock = 'Fill'
$form.Controls.Add($tabs)

$status = New-Object System.Windows.Forms.StatusStrip
$statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLabel.Text = 'Pronto.'
$status.Items.Add($statusLabel) | Out-Null
$form.Controls.Add($status)

function Set-Status([string]$msg) { $statusLabel.Text = $msg; $form.Refresh() }

# ---------------- Aba Resumo ----------------
$tabResumo = New-Object System.Windows.Forms.TabPage
$tabResumo.Text = 'Resumo'
$tabs.TabPages.Add($tabResumo) | Out-Null

$txtResumo = New-Object System.Windows.Forms.TextBox
$txtResumo.Multiline = $true
$txtResumo.ReadOnly = $true
$txtResumo.ScrollBars = 'Vertical'
$txtResumo.Font = New-Object System.Drawing.Font('Consolas', 10)
$txtResumo.Dock = 'Top'
$txtResumo.Height = 380
$tabResumo.Controls.Add($txtResumo)

$hw = Get-HardwareSummary
$txtResumo.Lines = $hw.GetEnumerator() | ForEach-Object { "$($_.Key): $($_.Value)" }

$btnDrivers = New-Object System.Windows.Forms.Button
$btnDrivers.Text = 'Exportar drivers'
$btnDrivers.Size = New-Object System.Drawing.Size(180, 36)
$btnDrivers.Location = New-Object System.Drawing.Point(12, 400)
$btnDrivers.Add_Click({
    Set-Status 'Exportando drivers... (pode demorar)'
    Export-WindowsDriver -Online -Destination (Join-Path $script:OutDir 'drivers') | Out-Null
    Set-Status 'Drivers exportados para inventario-pc\drivers.'
    [System.Windows.Forms.MessageBox]::Show('Drivers exportados.', 'InventarioPC')
})
$tabResumo.Controls.Add($btnDrivers)

$btnWifi = New-Object System.Windows.Forms.Button
$btnWifi.Text = 'Exportar Wi-Fi'
$btnWifi.Size = New-Object System.Drawing.Size(180, 36)
$btnWifi.Location = New-Object System.Drawing.Point(200, 400)
$btnWifi.Add_Click({
    $w = Join-Path $script:OutDir 'wifi'
    netsh wlan export profile folder="$w" key=clear | Out-Null
    Set-Status 'Perfis Wi-Fi exportados para inventario-pc\wifi.'
    [System.Windows.Forms.MessageBox]::Show('Senhas de Wi-Fi exportadas.', 'InventarioPC')
})
$tabResumo.Controls.Add($btnWifi)

$btnHtml = New-Object System.Windows.Forms.Button
$btnHtml.Text = 'Gerar relatório HTML'
$btnHtml.Size = New-Object System.Drawing.Size(180, 36)
$btnHtml.Location = New-Object System.Drawing.Point(388, 400)
$btnHtml.Add_Click({
    Set-Status 'Gerando relatório...'
    $css = '<style>body{font-family:"Segoe UI";background:#0f172a;color:#e2e8f0;padding:24px}h2{color:#38bdf8;border-bottom:1px solid #334155}table{border-collapse:collapse;width:100%;margin-bottom:24px}th{background:#1e293b;text-align:left;padding:6px}td{border-bottom:1px solid #1e293b;padding:6px;font-size:13px}.card{background:#1e293b;padding:12px;border-radius:8px;margin-bottom:16px}</style>'
    $progs = Get-InstalledPrograms
    $pastas = Get-UserFolderSizes
    $startup = Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, User
    $info = Get-HardwareSummary
    $html = "<html><head><meta charset='utf-8'>$css</head><body><h1>Inventário do PC</h1>"
    $html += "<div class='card'>" + (($info.GetEnumerator() | ForEach-Object { "<b>$($_.Key):</b> $($_.Value)" }) -join '<br>') + '</div>'
    $html += '<h2>Programas</h2>' + ($progs | ConvertTo-Html -Fragment)
    $html += '<h2>Pastas (GB)</h2>' + ($pastas | ConvertTo-Html -Fragment)
    $html += '<h2>Inicialização</h2>' + ($startup | ConvertTo-Html -Fragment)
    $html += '</body></html>'
    $html | Out-File (Join-Path $script:OutDir 'relatorio.html') -Encoding UTF8
    Set-Status 'Relatório gerado.'
    Invoke-Item (Join-Path $script:OutDir 'relatorio.html')
})
$tabResumo.Controls.Add($btnHtml)

# ---------------- Aba Programas ----------------
$tabProgs = New-Object System.Windows.Forms.TabPage
$tabProgs.Text = 'Programas'
$tabs.TabPages.Add($tabProgs) | Out-Null

$grid = New-Object System.Windows.Forms.DataGridView
$grid.Dock = 'Top'
$grid.Height = 440
$grid.AllowUserToAddRows = $false
$grid.AllowUserToDeleteRows = $false
$grid.AutoSizeColumnsMode = 'Fill'
$grid.SelectionMode = 'FullRowSelect'
$tabProgs.Controls.Add($grid)

$script:dt = New-Object System.Data.DataTable
[void]$script:dt.Columns.Add('Manter', [bool])
[void]$script:dt.Columns.Add('Programa', [string])
[void]$script:dt.Columns.Add('Versão', [string])
[void]$script:dt.Columns.Add('Editor', [string])
foreach ($p in (Get-InstalledPrograms)) {
    $row = $script:dt.NewRow()
    $row['Manter'] = $true
    $row['Programa'] = $p.DisplayName
    $row['Versão'] = $p.DisplayVersion
    $row['Editor'] = $p.Publisher
    $script:dt.Rows.Add($row)
}
$grid.DataSource = $script:dt
$grid.Columns['Manter'].ReadOnly = $false
$grid.Columns['Programa'].ReadOnly = $true
$grid.Columns['Versão'].ReadOnly = $true
$grid.Columns['Editor'].ReadOnly = $true

$btnTodos = New-Object System.Windows.Forms.Button
$btnTodos.Text = 'Marcar todos'
$btnTodos.Size = New-Object System.Drawing.Size(140, 32)
$btnTodos.Location = New-Object System.Drawing.Point(12, 452)
$btnTodos.Add_Click({ foreach ($r in $script:dt.Rows) { $r['Manter'] = $true } })
$tabProgs.Controls.Add($btnTodos)

$btnNenhum = New-Object System.Windows.Forms.Button
$btnNenhum.Text = 'Desmarcar todos'
$btnNenhum.Size = New-Object System.Drawing.Size(140, 32)
$btnNenhum.Location = New-Object System.Drawing.Point(160, 452)
$btnNenhum.Add_Click({ foreach ($r in $script:dt.Rows) { $r['Manter'] = $false } })
$tabProgs.Controls.Add($btnNenhum)

$btnSalvar = New-Object System.Windows.Forms.Button
$btnSalvar.Text = 'Salvar seleção'
$btnSalvar.Size = New-Object System.Drawing.Size(140, 32)
$btnSalvar.Location = New-Object System.Drawing.Point(308, 452)
$btnSalvar.Add_Click({
    $sel = @($script:dt.Rows | Where-Object { $_['Manter'] -eq $true } | ForEach-Object {
        [pscustomobject]@{ Programa = $_['Programa']; Versão = $_['Versão']; Editor = $_['Editor'] }
    })
    $sel | ConvertTo-Json -Depth 3 | Out-File (Join-Path $script:OutDir 'selecao.json') -Encoding UTF8
    $sel | Export-Csv (Join-Path $script:OutDir 'selecao.csv') -NoTypeInformation -Encoding UTF8
    Set-Status "Seleção salva: $($sel.Count) programas."
    [System.Windows.Forms.MessageBox]::Show("Seleção salva ($($sel.Count) programas).", 'InventarioPC')
})
$tabProgs.Controls.Add($btnSalvar)

# ---------------- Aba Pastas & Backup ----------------
$tabPastas = New-Object System.Windows.Forms.TabPage
$tabPastas.Text = 'Pastas && Backup'
$tabs.TabPages.Add($tabPastas) | Out-Null

$lstPastas = New-Object System.Windows.Forms.ListView
$lstPastas.View = 'Details'
$lstPastas.FullRowSelect = $true
$lstPastas.Dock = 'Top'
$lstPastas.Height = 400
[void]$lstPastas.Columns.Add('Pasta', 300)
[void]$lstPastas.Columns.Add('GB', 120)
$tabPastas.Controls.Add($lstPastas)

foreach ($f in (Get-UserFolderSizes)) {
    $item = New-Object System.Windows.Forms.ListViewItem($f.Pasta)
    [void]$item.SubItems.Add("$($f.GB)")
    $lstPastas.Items.Add($item) | Out-Null
}

$lblBackup = New-Object System.Windows.Forms.Label
$lblBackup.Text = 'Copie para o HD externo: Desktop, Documentos, Imagens, Downloads, saves de jogos e a pasta inventario-pc.'
$lblBackup.AutoSize = $false
$lblBackup.Size = New-Object System.Drawing.Size(860, 60)
$lblBackup.Location = New-Object System.Drawing.Point(12, 415)
$tabPastas.Controls.Add($lblBackup)

# ---------------- Aba Pós-formatação ----------------
$tabPos = New-Object System.Windows.Forms.TabPage
$tabPos.Text = 'Pós-formatação'
$tabs.TabPages.Add($tabPos) | Out-Null

$txtPos = New-Object System.Windows.Forms.TextBox
$txtPos.Multiline = $true
$txtPos.ReadOnly = $true
$txtPos.ScrollBars = 'Vertical'
$txtPos.Font = New-Object System.Drawing.Font('Consolas', 10)
$txtPos.Dock = 'Top'
$txtPos.Height = 380
$txtPos.Text = "1. Instale o Windows da ISO.`r`n2. Rode: winget import -i reinstalar.json`r`n3. Reinstale o resto pela selecao.csv.`r`n4. Confira drivers e Wi-Fi salvos."
$tabPos.Controls.Add($txtPos)

$btnWinget = New-Object System.Windows.Forms.Button
$btnWinget.Text = 'Exportar winget'
$btnWinget.Size = New-Object System.Drawing.Size(180, 36)
$btnWinget.Location = New-Object System.Drawing.Point(12, 400)
$btnWinget.Add_Click({
    Set-Status 'Exportando lista do winget...'
    winget export -o (Join-Path $script:OutDir 'reinstalar.json') --include-versions
    Set-Status 'reinstalar.json criado. Depois de formatar: winget import -i reinstalar.json'
    [System.Windows.Forms.MessageBox]::Show('reinstalar.json criado.', 'InventarioPC')
})
$tabPos.Controls.Add($btnWinget)

$btnAbrir = New-Object System.Windows.Forms.Button
$btnAbrir.Text = 'Abrir pasta'
$btnAbrir.Size = New-Object System.Drawing.Size(180, 36)
$btnAbrir.Location = New-Object System.Drawing.Point(200, 400)
$btnAbrir.Add_Click({ Invoke-Item $script:OutDir })
$tabPos.Controls.Add($btnAbrir)

Style-Grid $grid
Apply-Theme $form

[void]$form.ShowDialog()
