# WipeReady v2.1.1 - pre-format PC inventory with GUI
# Usage (on the PC to be formatted): double-click WipeReady.exe
# or: powershell -ExecutionPolicy Bypass -File App.ps1 (as admin)

#Requires -Version 5.1

$script:Version = '2.1.1'

# --- self-elevate ---
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) {
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$script:OutDir = Join-Path ([Environment]::GetFolderPath('Desktop')) 'wipeready'
New-Item -ItemType Directory -Force -Path $script:OutDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $script:OutDir 'wifi') | Out-Null

. "$PSScriptRoot/Theme.ps1"
. "$PSScriptRoot/Collect.ps1"
. "$PSScriptRoot/MainForm.ps1"
. "$PSScriptRoot/Tabs/Summary.ps1"
. "$PSScriptRoot/Tabs/Programs.ps1"
. "$PSScriptRoot/Tabs/Backup.ps1"
. "$PSScriptRoot/Tabs/Restore.ps1"

Set-DpiAwareness

New-AppShell
Register-Page 'Summary' (Add-SummaryTab)
Register-Page 'Programs' (Add-ProgramsTab)
Register-Page 'Backup' (Add-BackupTab)
Register-Page 'Restore' (Add-RestoreTab)
Show-Page 0
Show-App
