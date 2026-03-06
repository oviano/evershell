# evershell

Persistent remote terminal sessions with native scrollback. A standalone installation consisting of two services, no dependencies.

A host process runs on your server and owns shell sessions in pseudo-terminals. A network-facing agent handles client connections and delegates to the host via IPC. Sessions survive both client disconnects and agent restarts — when you reconnect, you get the full current screen state and you're back where you left off.

The server components are free and open source (MIT). An iOS client app is in private beta testing, with Android, macOS, Ubuntu and Windows clients planned.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/oviano/evershell/main/install.sh | bash
```

This will:

1. Download the latest release to `~/evershell/`
2. Install both `evershell-host` and `evershell-agent`
3. Create and start system services (launchd on macOS, systemd on Linux)
4. Auto-generate TLS certificates and an authentication token
5. Start listening on `0.0.0.0:8025`

The token is printed at the end of the install. You'll need it to connect from the app.

To install a specific version:

```bash
curl -fsSL https://raw.githubusercontent.com/oviano/evershell/main/install.sh | bash -s -- --version 0.9.0
```

## How it works

The host runs a terminal emulator (libvtermcpp) on the server side, maintaining a complete model of each session's screen state including scrollback history. The agent connects to the host via Unix domain socket and serves clients over the network.

When a client connects, it receives the full current state and scrollback — rendered natively with pixel-smooth scrolling. While attached, the agent fetches frames from the host, computes cell-level diffs, compresses them with zstd, and streams them over UDP (DTLS-encrypted). A separate TCP connection (TLS-encrypted) handles session management, keyboard input, and resize events.

The client uses speculative local echo (similar to Mosh) — printable keystrokes are rendered immediately before the server confirms them, hiding network latency.

Sessions continue running while disconnected. The host owns the PTY, so sessions even survive agent restarts. Reconnecting picks up right where you left off, even if the session produced output in the meantime.

## Why not tmux + mosh?

tmux and mosh are excellent tools, but combining them has trade-offs. tmux manages sessions and mosh handles latency, but scrollback requires workarounds — tmux's scrollback is its own buffer that doesn't integrate with your terminal's native scroll, so you lose natural gestures like trackpad flicking or pixel-smooth scrolling on mobile.

evershell is built for this specific use case. The host maintains scrollback on the server and streams it to the client as native content, so you get real scrollback with the scrolling behaviour your device expects. No configuration, no pairing two tools together, no scrollback hacks.

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
# Host
launchctl stop com.evershell.host
launchctl start com.evershell.host

# Agent
launchctl stop com.evershell.agent
launchctl start com.evershell.agent

# Logs
tail -f ~/evershell/logs/stderr.log
tail -f ~/evershell/logs/host-stderr.log
```

### Linux

```bash
# Host
systemctl --user stop evershell-host
systemctl --user start evershell-host

# Agent
systemctl --user stop evershell-agent
systemctl --user start evershell-agent

# Logs
journalctl --user -u evershell-host -f
journalctl --user -u evershell-agent -f
```

## Updating

Re-run the install script — it stops the running services, replaces the binaries, and restarts.

```bash
curl -fsSL https://raw.githubusercontent.com/oviano/evershell/main/install.sh | bash
```

Or manually:

```bash
# macOS
launchctl stop com.evershell.agent
launchctl stop com.evershell.host
cp /path/to/new/evershell-host ~/evershell/
cp /path/to/new/evershell-agent ~/evershell/
launchctl start com.evershell.host
launchctl start com.evershell.agent

# Linux
systemctl --user stop evershell-agent
systemctl --user stop evershell-host
cp /path/to/new/evershell-host ~/evershell/
cp /path/to/new/evershell-agent ~/evershell/
systemctl --user start evershell-host
systemctl --user start evershell-agent
```

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/oviano/evershell/main/uninstall.sh | bash
```

Stops the services and removes the binaries, settings, token, and TLS certificates.

## Configuration

Settings are in `settings.json`:

| Platform | Agent Settings | Host Settings |
|----------|---------------|---------------|
| macOS | `~/Library/Application Support/evershell/evershell-agent/settings.json` | `~/Library/Application Support/evershell/evershell-host/settings.json` |
| Linux | `~/.config/evershell/evershell-agent/settings.json` | `~/.config/evershell/evershell-host/settings.json` |

On first run, default settings are copied to these locations. Agent settings:

| Setting | Default | Description |
|---------|---------|-------------|
| `bind_address` | `0.0.0.0` | Listen address |
| `bind_port` | `8025` | Listen port |
| `enable_token_auth` | `true` | Require token authentication |
| `enable_tls` | `true` | TLS/DTLS encryption |
| `verbosity` | `1` | Log level: 0 = error, 1 = info, 2 = debug |
| `log_to_file` | `true` | Write to log file |
| `log_to_stdout` | `false` | Write to stdout |

Restart the services after changing settings.

## Security

- All traffic is encrypted with TLS (control channel) and DTLS (stream channel)
- Connections are authenticated with a 64-character hex token using constant-time comparison
- TLS certificates are self-signed and auto-generated on first run
- Both TLS and token auth are enabled by default
- Host-agent communication is via Unix domain socket (local only, not network-exposed)

## Troubleshooting

**Port already in use** — Another process is using port 8025. Change `bind_port` in the agent's settings.json, or find and stop the conflicting process.

**Can't connect from app** — Check that port 8025 is open for both **TCP and UDP** in your firewall. TCP is used for the control connection and UDP for the terminal stream. The agent listens on `0.0.0.0` by default (all interfaces). If behind NAT, you'll need to forward both protocols.

**Token not found** — The token is auto-generated on first run. Check the settings directory paths above. If the file doesn't exist, the agent hasn't started successfully — check the logs.

**Service won't start** — Check logs for errors:
```bash
# macOS
cat ~/evershell/logs/stderr.log
cat ~/evershell/logs/host-stderr.log

# Linux
journalctl --user -u evershell-agent --no-pager -n 20
journalctl --user -u evershell-host --no-pager -n 20
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
