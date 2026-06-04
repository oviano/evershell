@echo off
setlocal enabledelayedexpansion

REM Install evershell-agent on Windows as a background process (auto-start at logon).
REM
REM Usage:
REM   install-windows.cmd [BINARY_PATH]
REM
REM BINARY_PATH defaults to the latest build output.

REM --- Locate binary ---

set "SCRIPT_DIR=%~dp0"
set "INSTALL_DIR=%LOCALAPPDATA%\evershell"
set "REG_KEY=HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
set "REG_VALUE=Evershell Agent"

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

REM --- Stop existing process if running ---

tasklist /fi "imagename eq evershell-agent.exe" 2>nul | findstr /i "evershell-agent.exe" >nul
if !ERRORLEVEL! equ 0 (
    echo Stopping existing process...
    taskkill /f /im evershell-agent.exe >nul 2>&1
    timeout /t 2 /nobreak >nul
)

REM --- Install binary and default settings ---

echo Installing to %INSTALL_DIR%...
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
copy /y "%BINARY%" "%INSTALL_DIR%\evershell-agent.exe" >nul
xcopy /y /e /i "%DEFAULT_SETTINGS%" "%INSTALL_DIR%\default_settings" >nul

REM --- Register auto-start at logon ---

echo Registering auto-start...
reg add "!REG_KEY!" /v "!REG_VALUE!" /d "conhost.exe --headless \"!INSTALL_DIR!\evershell-agent.exe\"" /f >nul

REM --- Start process ---

echo Starting...
start "" conhost.exe --headless "!INSTALL_DIR!\evershell-agent.exe"

REM --- Wait for startup ---

timeout /t 3 /nobreak >nul

REM --- Show status ---

set "SETTINGS_DIR=%APPDATA%\evershell\evershell-agent"
set "TOKENS_FILE=%SETTINGS_DIR%\tokens.json"

echo.
echo Service running.
echo Settings: %SETTINGS_DIR%\settings.json
if exist "%TOKENS_FILE%" (
    for /f "tokens=2 delims=:" %%a in ('findstr /c:"\"token\"" "%TOKENS_FILE%"') do (
        set "TOKEN=%%~a"
        set "TOKEN=!TOKEN: =!"
        set "TOKEN=!TOKEN:"=!"
        set "TOKEN=!TOKEN:,=!"
        if not "!TOKEN!"=="" echo Token: !TOKEN!
    )
)
echo.
echo Service management:
echo   tasklist /fi "imagename eq evershell-agent.exe"
echo   taskkill /f /im evershell-agent.exe
echo   start "" "%INSTALL_DIR%\evershell-agent.exe"

exit /b 0 