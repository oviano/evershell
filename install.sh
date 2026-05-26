#!/bin/bash
#
# Install evershell-agent from GitHub Releases.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/oviano/evershell/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/oviano/evershell/main/install.sh | bash -s -- --version 1.2.0
#
# Platforms:
#   macOS  - downloads a signed/notarized/stapled .pkg + install-macos.sh,
#            installs to /usr/local/evershell-agent/ via `sudo installer`.
#   Linux  - downloads a tarball containing install-ubuntu.sh.

set -euo pipefail

REPO="oviano/evershell"
VERSION=""

while [ $# -gt 0 ]; do
    case "$1" in
        --version) VERSION="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

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
    x86_64|amd64)    ARCH_TAG="x86_64" ;;
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

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

if [ "$PLATFORM" = "macos" ]; then
    # macOS distribution is a signed/notarized/stapled .pkg installed via
    # `installer`. install-macos.sh is published alongside the .pkg in the
    # release assets so we can use it as the entry point.
    PKG="evershell-agent-${VERSION}-${PLATFORM}-${ARCH_TAG}.pkg"
    PKG_URL="https://github.com/${REPO}/releases/download/v${VERSION}/${PKG}"
    INSTALLER_URL="https://github.com/${REPO}/releases/download/v${VERSION}/install-macos.sh"

    echo "Downloading ${PKG_URL}..."
    if ! curl -fsSL "$PKG_URL" -o "${TMPDIR}/${PKG}"; then
        echo "ERROR: Download failed. Check the version and platform."
        echo "Available releases: https://github.com/${REPO}/releases"
        exit 1
    fi

    echo "Downloading install-macos.sh..."
    if ! curl -fsSL "$INSTALLER_URL" -o "${TMPDIR}/install-macos.sh"; then
        echo "ERROR: Could not fetch install-macos.sh from release assets"
        exit 1
    fi
    chmod +x "${TMPDIR}/install-macos.sh"
    "${TMPDIR}/install-macos.sh" "${TMPDIR}/${PKG}"
else
    # Linux distribution is a tarball containing install-ubuntu.sh.
    ARCHIVE="evershell-agent-${VERSION}-${PLATFORM}-${ARCH_TAG}.tar.gz"
    URL="https://github.com/${REPO}/releases/download/v${VERSION}/${ARCHIVE}"

    echo "Downloading ${URL}..."
    if ! curl -fsSL "$URL" -o "${TMPDIR}/${ARCHIVE}"; then
        echo "ERROR: Download failed. Check the version and platform."
        echo "Available releases: https://github.com/${REPO}/releases"
        exit 1
    fi

    tar xzf "${TMPDIR}/${ARCHIVE}" -C "$TMPDIR"

    if [ ! -f "${TMPDIR}/install-ubuntu.sh" ]; then
        echo "ERROR: install-ubuntu.sh not found in tarball"
        exit 1
    fi
    chmod +x "${TMPDIR}/install-ubuntu.sh"
    "${TMPDIR}/install-ubuntu.sh"
fi
