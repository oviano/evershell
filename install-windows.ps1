#
# Install evershell-agent on Windows as a background process (auto-start at logon).
#
# Usage:
#   .\install-windows.ps1 [BINARY_PATH]
#
# BINARY_PATH defaults to the latest build output:
#   ~\Git\builds\evershell-agent\evershell-agent-windows\x86_64\evershell-agent.exe
#

param(
    [Parameter(Position=0)]
    [string]$BinaryPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# --- Locate binary ---

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$InstallDir = "$env:LOCALAPPDATA\evershell"
$RegKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$RegValue = "Evershell Agent"

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

# --- Stop existing process if running ---

$existing = Get-Process -Name "evershell-agent" -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "Stopping existing process..."
    Stop-Process -Name "evershell-agent" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

# --- Install binary and default settings ---

Write-Host "Installing to $InstallDir..."
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
Copy-Item $Binary "$InstallDir\evershell-agent.exe" -Force
Copy-Item $DefaultSettings "$InstallDir\default_settings" -Recurse -Force

# --- Register auto-start at logon ---

Write-Host "Registering auto-start..."
Set-ItemProperty -Path $RegKey -Name $RegValue -Value "conhost.exe --headless `"$InstallDir\evershell-agent.exe`""

# --- Start process ---

Write-Host "Starting..."
Start-Process conhost.exe -ArgumentList "--headless `"$InstallDir\evershell-agent.exe`""

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
}

Write-Host ""
Write-Host "Service management:"
Write-Host "  Get-Process evershell-agent"
Write-Host "  Stop-Process -Name evershell-agent -Force"
Write-Host "  Start-Process `"$InstallDir\evershell-agent.exe`""

exit 0
