@echo off
setlocal enabledelayedexpansion

REM Uninstall evershell-agent on Windows.
REM
REM Usage:
REM   curl -fsSL https://raw.githubusercontent.com/oviano/evershell/main/uninstall.cmd -o uninstall.cmd && uninstall.cmd && del uninstall.cmd

set "INSTALL_DIR=%LOCALAPPDATA%\evershell"
set "SETTINGS_DIR=%APPDATA%\evershell"
set "BINARY=%INSTALL_DIR%\evershell-agent.exe"
set "REG_KEY=HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
set "REG_VALUE=Evershell Agent"

REM --- Stop process ---

tasklist /fi "imagename eq evershell-agent.exe" 2>nul | findstr /i "evershell-agent.exe" >nul
if !ERRORLEVEL! equ 0 (
    echo Stopping process...
    taskkill /f /im evershell-agent.exe >nul 2>&1
    timeout /t 2 /nobreak >nul
)

REM --- Remove auto-start registration ---

reg query "!REG_KEY!" /v "!REG_VALUE!" >nul 2>&1
if !ERRORLEVEL! equ 0 (
    echo Removing auto-start registration...
    reg delete "!REG_KEY!" /v "!REG_VALUE!" /f >nul
)

REM --- Remove install directory ---

if exist "%INSTALL_DIR%" (
    echo Removing %INSTALL_DIR%...
    rmdir /s /q "%INSTALL_DIR%"
)

REM --- Remove settings and data ---

if exist "%SETTINGS_DIR%" (
    echo Removing %SETTINGS_DIR%...
    rmdir /s /q "%SETTINGS_DIR%"
)

echo.
echo Evershell agent uninstalled.
