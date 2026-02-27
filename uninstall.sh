#!/bin/bash
#
# Uninstall evershell-agent.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/oviano/evershell-agent/main/uninstall.sh | bash
#

set -euo pipefail

OS="$(uname -s)"

case "$OS" in
    Darwin)
        SERVICE_LABEL="com.evershell.agent"
        PLIST_FILE="$HOME/Library/LaunchAgents/${SERVICE_LABEL}.plist"
        SETTINGS_DIR="$HOME/Library/Application Support/evershell"

        # Stop and remove service
        if launchctl list "$SERVICE_LABEL" &>/dev/null; then
            echo "Stopping service..."
            launchctl stop "$SERVICE_LABEL" 2>/dev/null || true
            launchctl unload "$PLIST_FILE" 2>/dev/null || true
        fi
        rm -f "$PLIST_FILE"
        ;;
    Linux)
        SERVICE_NAME="evershell-agent"

        # Stop and remove service
        if systemctl --user is-active "$SERVICE_NAME" &>/dev/null; then
            echo "Stopping service..."
            systemctl --user stop "$SERVICE_NAME"
        fi
        systemctl --user disable "$SERVICE_NAME" 2>/dev/null || true
        rm -f "$HOME/.config/systemd/user/${SERVICE_NAME}.service"
        systemctl --user daemon-reload 2>/dev/null || true

        SETTINGS_DIR="$HOME/.config/evershell"
        ;;
    *)
        echo "Unsupported OS: $OS"
        exit 1
        ;;
esac

# Remove binary and logs
if [ -d "$HOME/evershell" ]; then
    echo "Removing $HOME/evershell..."
    rm -rf "$HOME/evershell"
fi

# Remove settings, token, and TLS certs
if [ -d "$SETTINGS_DIR" ]; then
    echo "Removing $SETTINGS_DIR..."
    rm -rf "$SETTINGS_DIR"
fi

echo "Uninstalled."
