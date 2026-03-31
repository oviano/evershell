#
# Install evershell-agent on Windows as a Windows service.
#
# Usage:
#   .\install-windows.ps1 [BINARY_PATH]
#
# BINARY_PATH defaults to the latest build output:
#   ~\Git\builds\evershell-agent\evershell-agent-windows\x86_64\evershell-agent.exe
#
# Must be run as Administrator (service registration requires it).
#

param(
    [Parameter(Position=0)]
    [string]$BinaryPath
)

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

# --- Locate binary ---

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$InstallDir = "$env:LOCALAPPDATA\evershell"
$ServiceName = "Evershell Agent"

if ($BinaryPath) {
    $Binary = $BinaryPath
} elseif (Test-Path "$ScriptDir\evershell-agent.exe") {
    $Binary = "$ScriptDir\evershell-agent.exe"
} else {
    $Binary = "$env:USERPROFILE\Git\builds\evershell-agent\evershell-agent-windows\x86_64\evershell-agent.exe"
}

if (-not (Test-Path $Binary)) {
    Write-Host "ERROR: Binary not found: $Binary"
    Write-Host "Build it first: build.cmd evershell-agent -p windows"
    exit 1
}

# --- Locate default_settings ---

$DefaultSettings = "$ScriptDir\resources\default_settings"
if (-not (Test-Path $DefaultSettings)) {
    Write-Host "ERROR: default_settings not found at: $DefaultSettings"
    exit 1
}

# --- Stop existing service if running ---

$service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($service -and $service.Status -eq 'Running') {
    Write-Host "Stopping existing service..."
    & "$InstallDir\evershell-agent.exe" stop
    Start-Sleep -Seconds 2
}

# --- Uninstall existing service if registered ---

if ($service) {
    Write-Host "Removing existing service registration..."
    & "$InstallDir\evershell-agent.exe" uninstall
    Start-Sleep -Seconds 1
}

# --- Install binary and default settings ---

Write-Host "Installing to $InstallDir..."
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
Copy-Item $Binary "$InstallDir\evershell-agent.exe" -Force
Copy-Item $DefaultSettings "$InstallDir\default_settings" -Recurse -Force

# --- Register and start service ---

Write-Host "Registering service..."
& "$InstallDir\evershell-agent.exe" install
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Service registration failed."
    exit 1
}

Write-Host "Starting service..."
& "$InstallDir\evershell-agent.exe" start
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Service failed to start."
    exit 1
}

# --- Wait for startup ---

Start-Sleep -Seconds 3

# --- Show token and status ---

$SettingsDir = "$env:APPDATA\evershell\evershell-agent"
$TokensFile = "$SettingsDir\tokens.json"

if (Test-Path $TokensFile) {
    $tokens = Get-Content $TokensFile -Raw | ConvertFrom-Json
    if ($tokens.Count -gt 0) {
        Write-Host ""
        Write-Host "Service running."
        Write-Host "Token: $($tokens[0].token)"
        Write-Host "Settings: $SettingsDir\settings.json"
    }
} else {
    Write-Host ""
    Write-Host "Service running."
    Write-Host "Settings: $SettingsDir\settings.json"
    Write-Host "(Token will be generated on first startup)"
}

Write-Host ""
Write-Host "Service management:"
Write-Host "  sc query `"$ServiceName`""
Write-Host "  $InstallDir\evershell-agent.exe stop"
Write-Host "  $InstallDir\evershell-agent.exe start"
Write-Host "  Get-Content $SettingsDir\evershell-agent.log -Tail 20"
