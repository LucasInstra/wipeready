# WipeReady build: bundles src/*.ps1 into one file and compiles WipeReady.exe
# Usage: powershell -ExecutionPolicy Bypass -File build/Build.ps1
# Requires: ps2exe module (Install-Module ps2exe -Scope CurrentUser)

$root = Split-Path -Parent $PSScriptRoot
$entry = Get-Content (Join-Path $root 'src/App.ps1') -Raw

$bundle = [regex]::Replace($entry, '(?m)^\s*\.\s*"\$PSScriptRoot/([^"]+)"\s*(#.*)?$', {
    param($m)
    "`n# ===== bundled: src/$($m.Groups[1].Value) =====`n" +
        (Get-Content (Join-Path $root ('src/' + $m.Groups[1].Value)) -Raw)
})

$dist = Join-Path $root 'dist'
New-Item -ItemType Directory -Force -Path $dist | Out-Null
$bundlePath = Join-Path $dist 'WipeReady.bundle.ps1'
# Explicit UTF-8 BOM: without it PowerShell reads non-ASCII chars as ANSI.
[System.IO.File]::WriteAllText($bundlePath, $bundle, (New-Object System.Text.UTF8Encoding $true))

$ErrorActionPreference = 'Stop'
try {
    Invoke-PS2EXE -InputFile $bundlePath `
        -OutputFile (Join-Path $root 'WipeReady.exe') `
        -noConsole -requireAdmin `
        -title 'WipeReady' -description 'Pre-format PC inventory' -company 'WipeReady'
} catch {
    Write-Host ("BUILD FAILED: " + $_.Exception.Message)
    exit 1
}

Write-Host 'Build done: WipeReady.exe'
