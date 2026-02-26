# evershell

Persistent remote terminal sessions with native scrollback. A single standalone binary, no dependencies.

An agent runs on your server and hosts shell sessions that survive disconnects. When you reconnect, your session is exactly where you left it — the agent tracks output and sends only what changed. No full-screen flash, no visual reset.

The agent is free and open source (MIT). The [iOS and macOS app](https://apps.apple.com) connects to it.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/oviano/evershell/main/install.sh | bash
```

This downloads the latest release, installs the binary to `~/evershell/`, sets up a system service, and prints your authentication token.

### Specific version

```bash
curl -fsSL https://raw.githubusercontent.com/oviano/evershell/main/install.sh | bash -s -- --version 1.0.0
```

## What happens

1. The binary is installed to `~/evershell/evershell-agent`
2. A system service is created and started (launchd on macOS, systemd on Linux)
3. TLS certificates and an authentication token are auto-generated
4. The agent listens on `0.0.0.0:8025`

The token is printed at the end of the install. You'll need it to connect from the app.

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
curl -fsSL https://raw.githubusercontent.com/oviano/evershell/main/install.sh | bash
```

Or manually:

```bash
# macOS
launchctl stop com.evershell.agent
cp /path/to/new/evershell-agent ~/evershell/
codesign --force --sign - ~/evershell/evershell-agent
launchctl start com.evershell.agent

# Linux
systemctl --user stop evershell-agent
cp /path/to/new/evershell-agent ~/evershell/
systemctl --user start evershell-agent
```

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

**Can't connect from app** — Check that the port is open in your firewall. The agent listens on `0.0.0.0` by default (all interfaces). If behind NAT, you'll need to forward port 8025 (TCP and UDP).

**Token not found** — The token is auto-generated on first run. Check the settings directory paths above. If the file doesn't exist, the agent hasn't started successfully — check the logs.

**Service won't start** — Check logs for errors:
```bash
# macOS
cat ~/evershell/logs/stderr.log

# Linux
journalctl --user -u evershell-agent --no-pager -n 20
```

## Platforms

| Platform | Status |
|----------|--------|
| macOS (Apple Silicon / Intel) | Supported |
| Linux x86_64 | Supported |
| Windows | Coming soon |

## License

MIT
