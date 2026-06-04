#
# Install evershell-agent from GitHub Releases.
#
# Usage:
#   irm https://raw.githubusercontent.com/oviano/evershell/main/install.ps1 | iex
#   .\install.ps1 -Version 0.9.0
#

param(
    [Parameter(Position=0)]
    [string]$Version
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'

function Invoke-EvershellInstall {
    param([string]$Version)

    # --- Detect architecture ---

    $Repo = "oviano/evershell"
    $Arch = if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { "arm_64" } else { "x86_64" }

    # --- Get latest version if not specified ---

    if (-not $Version) {
        Write-Host "Fetching latest release..."
        try {
            $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest"
            $Version = $release.tag_name -replace '^v', ''
        } catch {
            Write-Host "ERROR: Could not fetch latest release"
            return 1
        }
    }

    Write-Host "Installing evershell-agent v$Version..."

    # --- Download tarball ---

    $Archive = "evershell-agent-$Version-windows-$Arch.tar.gz"
    $Url = "https://github.com/$Repo/releases/download/v$Version/$Archive"
    $TmpDir = Join-Path $env:TEMP "evershell-install"

    if (Test-Path $TmpDir) { Remove-Item $TmpDir -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $TmpDir | Out-Null

    Write-Host "Downloading $Url..."
    try {
        Invoke-WebRequest -Uri $Url -OutFile (Join-Path $TmpDir $Archive)
    } catch {
        Write-Host "ERROR: Download failed. Check the version and platform."
        Write-Host "Available releases: https://github.com/$Repo/releases"
        Remove-Item $TmpDir -Recurse -Force
        return 1
    }

    # --- Extract ---

    tar xzf (Join-Path $TmpDir $Archive) -C $TmpDir
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Extraction failed"
        Remove-Item $TmpDir -Recurse -Force
        return 1
    }

    # --- Run local installer ---

    $LocalInstaller = Join-Path $TmpDir "install-windows.ps1"
    if (-not (Test-Path $LocalInstaller)) {
        Write-Host "ERROR: install-windows.ps1 not found in tarball"
        Remove-Item $TmpDir -Recurse -Force
        return 1
    }

    & $LocalInstaller
    $InstallResult = $LASTEXITCODE

    # --- Clean up ---

    Remove-Item $TmpDir -Recurse -Force

    return $InstallResult
}

$code = Invoke-EvershellInstall -Version $Version

# Only `exit` when run as a script file (.\install.ps1 / -File), where it merely
# ends the script. Under `irm ... | iex` the body runs in the caller's own
# interactive session, so a top-level `exit` would close their PowerShell window
# before they can read the token/output. $PSCommandPath is empty in that case.
if ($PSCommandPath) {
    exit $code
}
