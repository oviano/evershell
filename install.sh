#!/bin/bash
#
# Install evershell-agent from GitHub Releases.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/oviano/evershell-agent/master/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/oviano/evershell-agent/master/install.sh | bash -s -- --version 1.2.0
#

set -euo pipefail

REPO="oviano/evershell-agent"
VERSION=""

# Parse arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --version) VERSION="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Detect platform
OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
    Linux)  PLATFORM="ubuntu" ;;
    Darwin) PLATFORM="macos" ;;
    *)
        echo "Unsupported OS: $OS"
        exit 1
        ;;
esac

case "$ARCH" in
    x86_64|amd64)   ARCH_TAG="x86_64" ;;
    arm64|aarch64)   ARCH_TAG="arm_64" ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# macOS uses universal binary
if [ "$PLATFORM" = "macos" ]; then
    ARCH_TAG="multi"
fi

# Get latest version from GitHub if not specified
if [ -z "$VERSION" ]; then
    echo "Fetching latest release..."
    VERSION=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
        | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"v\{0,1\}\([^"]*\)".*/\1/')

    if [ -z "$VERSION" ]; then
        echo "ERROR: Could not determine latest version"
        exit 1
    fi
fi

echo "Installing evershell-agent v${VERSION} (${PLATFORM}/${ARCH_TAG})..."

# Download archive
case "$PLATFORM" in
    macos)  EXT="zip" ;;
    *)      EXT="tar.gz" ;;
esac
ARCHIVE="evershell-agent-${VERSION}-${PLATFORM}-${ARCH_TAG}.${EXT}"
URL="https://github.com/${REPO}/releases/download/v${VERSION}/${ARCHIVE}"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

echo "Downloading ${URL}..."
if ! curl -fsSL "$URL" -o "${TMPDIR}/${ARCHIVE}"; then
    echo "ERROR: Download failed. Check the version and platform."
    echo "Available releases: https://github.com/${REPO}/releases"
    exit 1
fi

# Extract
case "$EXT" in
    zip)    unzip -qo "${TMPDIR}/${ARCHIVE}" -d "$TMPDIR" ;;
    tar.gz) tar xzf "${TMPDIR}/${ARCHIVE}" -C "$TMPDIR" ;;
esac

# Run platform-specific installer
case "$PLATFORM" in
    ubuntu)
        if [ ! -f "${TMPDIR}/install-ubuntu.sh" ]; then
            echo "ERROR: install-ubuntu.sh not found in tarball"
            exit 1
        fi
        chmod +x "${TMPDIR}/install-ubuntu.sh"
        "${TMPDIR}/install-ubuntu.sh"
        ;;
    macos)
        if [ ! -f "${TMPDIR}/install-macos.sh" ]; then
            echo "ERROR: install-macos.sh not found in tarball"
            exit 1
        fi
        chmod +x "${TMPDIR}/install-macos.sh"
        "${TMPDIR}/install-macos.sh"
        ;;
esac
