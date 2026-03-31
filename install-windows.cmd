@echo off
setlocal enabledelayedexpansion

REM Install evershell-agent on Windows as a Windows service.
REM
REM Usage:
REM   install-windows.cmd [BINARY_PATH]
REM
REM BINARY_PATH defaults to the latest build output.
REM Must be run as Administrator (service registration requires it).

REM --- Check Administrator ---

net session >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: This script must be run as Administrator.
    echo Right-click Command Prompt and select 'Run as administrator', then re-run this script.
    exit /b 1
)

REM --- Locate binary ---

set "SCRIPT_DIR=%~dp0"
set "INSTALL_DIR=%LOCALAPPDATA%\evershell"
set "SERVICE_NAME=Evershell Agent"

if "%~1" neq "" (
    set "BINARY=%~1"
) else if exist "%SCRIPT_DIR%evershell-agent.exe" (
    set "BINARY=%SCRIPT_DIR%evershell-agent.exe"
) else (
    set "BINARY=%USERPROFILE%\Git\builds\evershell-agent\evershell-agent-windows\x86_64\evershell-agent.exe"
)

if not exist "%BINARY%" (
    echo ERROR: Binary not found: %BINARY%
    echo Build it first: build.cmd evershell-agent -p windows
    exit /b 1
)

REM --- Locate default_settings ---

set "DEFAULT_SETTINGS=%SCRIPT_DIR%resources\default_settings"
if not exist "%DEFAULT_SETTINGS%" (
    echo ERROR: default_settings not found at: %DEFAULT_SETTINGS%
    exit /b 1
)

REM --- Stop existing service if running ---

sc query "%SERVICE_NAME%" >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo Stopping existing service...
    "%INSTALL_DIR%\evershell-agent.exe" stop 2>nul
    timeout /t 2 /nobreak >nul

    echo Removing existing service registration...
    "%INSTALL_DIR%\evershell-agent.exe" uninstall 2>nul
    timeout /t 1 /nobreak >nul
)

REM --- Install binary and default settings ---

echo Installing to %INSTALL_DIR%...
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
copy /y "%BINARY%" "%INSTALL_DIR%\evershell-agent.exe" >nul
xcopy /y /e /i "%DEFAULT_SETTINGS%" "%INSTALL_DIR%\default_settings" >nul

REM --- Register and start service ---

echo Registering service...
"%INSTALL_DIR%\evershell-agent.exe" install
if %ERRORLEVEL% neq 0 (
    echo ERROR: Service registration failed.
    exit /b 1
)

echo Starting service...
"%INSTALL_DIR%\evershell-agent.exe" start
if %ERRORLEVEL% neq 0 (
    echo ERROR: Service failed to start.
    exit /b 1
)

REM --- Wait for startup ---

timeout /t 3 /nobreak >nul

REM --- Show status ---

set "SETTINGS_DIR=%APPDATA%\evershell\evershell-agent"
set "TOKENS_FILE=%SETTINGS_DIR%\tokens.json"

echo.
echo Service running.
echo Settings: %SETTINGS_DIR%\settings.json
if exist "%TOKENS_FILE%" (
    echo Token: see %TOKENS_FILE%
)
echo.
echo Service management:
echo   sc query "%SERVICE_NAME%"
echo   %INSTALL_DIR%\evershell-agent.exe stop
echo   %INSTALL_DIR%\evershell-agent.exe start
