@echo off
setlocal enabledelayedexpansion

REM Uninstall evershell-agent on Windows.
REM
REM Usage:
REM   curl -fsSL https://raw.githubusercontent.com/oviano/evershell/main/uninstall.cmd -o uninstall.cmd && uninstall.cmd && del uninstall.cmd
REM
REM Must be run as Administrator.

REM --- Check Administrator ---

net session >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: This script must be run as Administrator.
    echo Right-click Command Prompt and select 'Run as administrator', then re-run this script.
    exit /b 1
)

set "INSTALL_DIR=%LOCALAPPDATA%\evershell"
set "SETTINGS_DIR=%APPDATA%\evershell"
set "BINARY=%INSTALL_DIR%\evershell-agent.exe"

REM --- Stop and uninstall service ---

if exist "%BINARY%" (
    echo Stopping service...
    "%BINARY%" stop 2>nul
    timeout /t 2 /nobreak >nul

    echo Uninstalling service...
    "%BINARY%" uninstall 2>nul
    timeout /t 1 /nobreak >nul
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
