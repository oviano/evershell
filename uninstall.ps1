#
# Uninstall evershell-agent on Windows.
#
# Usage:
#   irm https://raw.githubusercontent.com/oviano/evershell/main/uninstall.ps1 | iex
#
# Must be run as Administrator.
#

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# --- Check Administrator ---

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator."
    Write-Host "Right-click PowerShell and select 'Run as administrator', then re-run this script."
    exit 1
}

$InstallDir = "$env:LOCALAPPDATA\evershell"
$SettingsDir = "$env:APPDATA\evershell"
$Binary = "$InstallDir\evershell-agent.exe"

# --- Stop and uninstall service ---

if (Test-Path $Binary) {
    Write-Host "Stopping service..."
    & $Binary stop 2>$null
    Start-Sleep -Seconds 2

    Write-Host "Uninstalling service..."
    & $Binary uninstall 2>$null
    Start-Sleep -Seconds 1
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
