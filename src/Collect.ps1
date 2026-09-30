# WipeReady data collection (read-only, never modifies the system)

function Get-HardwareSummary {
    $cs  = Get-CimInstance Win32_ComputerSystem
    $os  = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $gpu = (Get-CimInstance Win32_VideoController | Select-Object -First 1).Name
    $key = (Get-CimInstance SoftwareLicensingService).OA3xOriginalProductKey
    if (-not $key) { $key = '(not stored in firmware)' }
    $diskHealth = 'Unknown'
    try {
        $pred = Get-CimInstance -Namespace root/wmi -Class MSStorageDriver_FailurePredictStatus -ErrorAction Stop
        if (@($pred | Where-Object { $_.PredictFailure }).Count -gt 0) {
            $diskHealth = 'FAIL - replace the drive before trusting backups to it'
        } else {
            $diskHealth = 'OK'
        }
    } catch { }
    return [ordered]@{
        'Machine'    = "$($cs.Manufacturer) $($cs.Model)"
        'CPU'        = $cpu.Name
        'RAM (GB)'   = [math]::Round($cs.TotalPhysicalMemory / 1GB)
        'GPU'        = $gpu
        'DiskHealth' = $diskHealth
        'OS'         = "$($os.Caption) ($($os.Version))"
        'Installed'  = $os.InstallDate
        'ProductKey' = $key
    }
}

function Get-InstalledPrograms {
    $paths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        # Per-user installs. NOTE: when elevated with different admin
        # credentials, HKCU is that admin's hive, not the user's.
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
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
        [pscustomobject]@{ Folder = $_.Name; GB = [math]::Round($sum / 1GB, 2) }
    } | Sort-Object GB -Descending
}
