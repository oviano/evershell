# evershell

Persistent remote terminal sessions with native scrollback. A single standalone binary, no dependencies.

An agent runs on your server and hosts shell sessions in pseudo-terminals. Sessions survive disconnects — when you reconnect, the agent sends the full current screen state and you're back where you left off.

The agent is free and open source (MIT). An iOS client app is in private beta testing, with Android, macOS, Ubuntu and Windows clients planned.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/oviano/evershell-agent/main/install.sh | bash
```

This will:

1. Download the latest release to `~/evershell/evershell-agent`
2. Create and start a system service (launchd on macOS, systemd on Linux)
3. Auto-generate TLS certificates and an authentication token
4. Start listening on `0.0.0.0:8025`

The token is printed at the end of the install. You'll need it to connect from the app.

To install a specific version:

```bash
curl -fsSL https://raw.githubusercontent.com/oviano/evershell-agent/main/install.sh | bash -s -- --version 0.9.0
```

## How it works

The agent runs a terminal emulator (libvtermcpp) on the server side, maintaining a complete model of each session's screen state including scrollback history.

When a client connects, it receives the full current state and scrollback — rendered natively with pixel-smooth scrolling. While attached, the agent computes cell-level diffs of the terminal screen, compresses them with zstd, and streams them over UDP (DTLS-encrypted). A separate TCP connection (TLS-encrypted) handles session management, keyboard input, and resize events.

The client uses speculative local echo (similar to Mosh) — printable keystrokes are rendered immediately before the server confirms them, hiding network latency.

Sessions continue running while disconnected. Reconnecting picks up right where you left off, even if the session produced output in the meantime.

## Why not tmux + mosh?

tmux and mosh are excellent tools, but combining them has trade-offs. tmux manages sessions and mosh handles latency, but scrollback requires workarounds — tmux's scrollback is its own buffer that doesn't integrate with your terminal's native scroll, so you lose natural gestures like trackpad flicking or pixel-smooth scrolling on mobile.

evershell is a single binary built for this specific use case. The agent maintains scrollback on the server and streams it to the client as native content, so you get real scrollback with the scrolling behaviour your device expects. No configuration, no pairing two tools together, no scrollback hacks.

The project was inspired by the need for easy long-running Claude Code sessions that just work — connect from your phone, check on progress, disconnect, reconnect later from your laptop, and everything is still there, in a modern, sleek UI.

## Connecting from the app

1. Open the evershell app
2. Add a new agent — enter your server's IP/hostname, port `8025`
3. Paste the authentication token
4. TLS is on by default — leave it enabled

To retrieve your token later:

```bash
# macOS
cat ~/Library/Application\ Support/evershell/evershell-agent/token

# Linux
cat ~/.config/evershell/evershell-agent/token
```

## Service management

### macOS

```bash
launchctl stop com.evershell.agent
launchctl start com.evershell.agent

# Logs
tail -f ~/evershell/logs/stderr.log
```

### Linux

```bash
systemctl --user stop evershell-agent
systemctl --user start evershell-agent
systemctl --user restart evershell-agent

# Logs
journalctl --user -u evershell-agent -f
```

## Updating

Re-run the install script — it stops the running service, replaces the binary, and restarts.

```bash
curl -fsSL https://raw.githubusercontent.com/oviano/evershell-agent/main/install.sh | bash
```

Or manually:

```bash
# macOS
launchctl stop com.evershell.agent
cp /path/to/new/evershell-agent ~/evershell/
launchctl start com.evershell.agent

# Linux
systemctl --user stop evershell-agent
cp /path/to/new/evershell-agent ~/evershell/
systemctl --user start evershell-agent
```

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/oviano/evershell-agent/main/uninstall.sh | bash
```

Stops the service and removes the binary, settings, token, and TLS certificates.

## Configuration

Settings are in `settings.json`:

| Platform | Path |
|----------|------|
| macOS | `~/Library/Application Support/evershell/evershell-agent/settings.json` |
| Linux | `~/.config/evershell/evershell-agent/settings.json` |

On first run, the agent copies default settings to this location. Edit to customise:

| Setting | Default | Description |
|---------|---------|-------------|
| `bind_address` | `0.0.0.0` | Listen address |
| `bind_port` | `8025` | Listen port |
| `enable_token_auth` | `true` | Require token authentication |
| `enable_tls` | `true` | TLS/DTLS encryption |
| `verbosity` | `1` | Log level: 0 = error, 1 = info, 2 = debug |
| `log_to_file` | `true` | Write to log file |
| `log_to_stdout` | `false` | Write to stdout |

Restart the service after changing settings.

## Security

- All traffic is encrypted with TLS (control channel) and DTLS (stream channel)
- Connections are authenticated with a 64-character hex token using constant-time comparison
- TLS certificates are self-signed and auto-generated on first run
- Both TLS and token auth are enabled by default

## Troubleshooting

**Port already in use** — Another process is using port 8025. Change `bind_port` in settings.json, or find and stop the conflicting process.

**Can't connect from app** — Check that port 8025 is open for both **TCP and UDP** in your firewall. TCP is used for the control connection and UDP for the terminal stream. The agent listens on `0.0.0.0` by default (all interfaces). If behind NAT, you'll need to forward both protocols.

**Token not found** — The token is auto-generated on first run. Check the settings directory paths above. If the file doesn't exist, the agent hasn't started successfully — check the logs.

**Service won't start** — Check logs for errors:
```bash
# macOS
cat ~/evershell/logs/stderr.log

# Linux
journalctl --user -u evershell-agent --no-pager -n 20
```

## Requirements

**macOS** — No dependencies.

**Linux** — Requires `libdbus-1`. Present on all standard Ubuntu installs. On minimal/container setups: `sudo apt install libdbus-1-3`

## Platforms

| Platform | Status |
|----------|--------|
| macOS (Apple Silicon / Intel) | Supported |
| Linux x86_64 | Supported |
| Windows | Coming soon |

## License

Released under the [MIT License](LICENSE).
