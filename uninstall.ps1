#
# Uninstall evershell-agent on Windows.
#
# Usage:
#   irm https://raw.githubusercontent.com/oviano/evershell/main/uninstall.ps1 | iex
#

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$InstallDir = "$env:LOCALAPPDATA\evershell"
$SettingsDir = "$env:APPDATA\evershell"
$Binary = "$InstallDir\evershell-agent.exe"
$RegKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$RegValue = "Evershell Agent"

# --- Stop process ---

$existing = Get-Process -Name "evershell-agent" -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "Stopping process..."
    Stop-Process -Name "evershell-agent" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

# --- Remove auto-start registration ---

$regEntry = Get-ItemProperty -Path $RegKey -Name $RegValue -ErrorAction SilentlyContinue
if ($regEntry) {
    Write-Host "Removing auto-start registration..."
    Remove-ItemProperty -Path $RegKey -Name $RegValue -Force
}

# --- Remove install directory ---

if (Test-Path $InstallDir) {
    Write-Host "Removing $InstallDir..."
    Remove-Item -Recurse -Force $InstallDir
}

# --- Remove settings and data ---

if (Test-Path $SettingsDir) {
    Write-Host "Removing $SettingsDir..."
    Remove-Item -Recurse -Force $SettingsDir
}

Write-Host ""
Write-Host "Evershell agent uninstalled."
