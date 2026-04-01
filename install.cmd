@echo off
setlocal enabledelayedexpansion

REM Install evershell-agent from GitHub Releases.
REM
REM Usage:
REM   curl -fsSL https://raw.githubusercontent.com/oviano/evershell/main/install.cmd -o install.cmd && install.cmd && del install.cmd
REM   install.cmd --version 0.9.0

REM --- Check Administrator ---

net session >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: This script must be run as Administrator.
    echo Right-click Command Prompt and select 'Run as administrator', then re-run this script.
    exit /b 1
)

REM --- Parse arguments ---

set "VERSION="
:parse_args
if "%~1"=="" goto :args_done
if /i "%~1"=="--version" (
    set "VERSION=%~2"
    shift
    shift
    goto :parse_args
)
echo Unknown option: %~1
exit /b 1
:args_done

REM --- Detect architecture ---

set "ARCH=x86_64"
if /i "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "ARCH=arm_64"

REM --- Get latest version if not specified ---

set "REPO=oviano/evershell"
set "TMPDIR=%TEMP%\evershell-install"
if exist "!TMPDIR!" rmdir /s /q "!TMPDIR!"
mkdir "!TMPDIR!"

if "!VERSION!"=="" (
    echo Fetching latest release...
    curl -fsSL "https://api.github.com/repos/%REPO%/releases/latest" -o "!TMPDIR!\release.json"
    if !ERRORLEVEL! neq 0 (
        echo ERROR: Could not fetch latest release
        exit /b 1
    )
    for /f "tokens=2 delims=:," %%a in ('findstr /c:"\"tag_name\"" "!TMPDIR!\release.json"') do (
        set "TAG=%%~a"
        set "TAG=!TAG: =!"
        set "TAG=!TAG:"=!"
        set "VERSION=!TAG:v=!"
    )
    del "!TMPDIR!\release.json"
)

if "!VERSION!"=="" (
    echo ERROR: Could not determine latest version
    exit /b 1
)

echo Installing evershell-agent v!VERSION!...

REM --- Download tarball ---

set "ARCHIVE=evershell-agent-!VERSION!-windows-!ARCH!.tar.gz"
set "URL=https://github.com/%REPO%/releases/download/v!VERSION!/!ARCHIVE!"

echo Downloading !URL!...
curl -fsSL "!URL!" -o "!TMPDIR!\!ARCHIVE!"
if !ERRORLEVEL! neq 0 (
    echo ERROR: Download failed. Check the version and platform.
    echo Available releases: https://github.com/%REPO%/releases
    rmdir /s /q "!TMPDIR!"
    exit /b 1
)

REM --- Extract ---

tar xzf "!TMPDIR!\!ARCHIVE!" -C "!TMPDIR!"
if !ERRORLEVEL! neq 0 (
    echo ERROR: Extraction failed
    rmdir /s /q "!TMPDIR!"
    exit /b 1
)

REM --- Run local installer ---

if not exist "!TMPDIR!\install-windows.cmd" (
    echo ERROR: install-windows.cmd not found in tarball
    rmdir /s /q "!TMPDIR!"
    exit /b 1
)

call "!TMPDIR!\install-windows.cmd"
set "INSTALL_RESULT=!ERRORLEVEL!"

REM --- Clean up ---

rmdir /s /q "!TMPDIR!"
exit /b !INSTALL_RESULT!
