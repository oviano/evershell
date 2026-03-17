# evershell

Persistent remote terminal sessions with native scrollback and smart notifications. A single-binary installation, no dependencies.

The agent runs on your server and manages shell sessions in pseudo-terminals. Sessions survive both client disconnects and agent restarts — when you reconnect, you get the full current screen state and you're back where you left off. While disconnected, AI watches your sessions and sends push notifications when something needs your attention.

The server is free and open source (MIT). An iOS client app is in private beta testing, with Android, macOS, Ubuntu and Windows clients planned.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/oviano/evershell/main/install.sh | bash
```

This will:

1. Download the latest release to `~/evershell/`
2. Install the agent and create a system service (launchd on macOS, systemd on Linux)
3. Auto-generate TLS certificates and an authentication token
4. Start listening on `0.0.0.0:8025`

The token is printed at the end of the install. You'll need it to connect from the app.

To install a specific version:

```bash
curl -fsSL https://raw.githubusercontent.com/oviano/evershell/main/install.sh | bash -s -- --version 0.9.0
```

## How it works

For each session, the agent runs a server-side terminal emulator (libvtermcpp), maintaining a complete model of the screen state including scrollback history.

When a client connects, it receives the full current state and scrollback — rendered natively with pixel-smooth scrolling. While attached, the agent computes cell-level diffs, compresses them with zstd, and streams them over UDP (DTLS-encrypted). Keyboard input flows back over the same UDP channel for minimal latency. A separate TCP connection (TLS-encrypted) handles session management and resize events.

The client uses speculative local echo (similar to Mosh) — printable keystrokes are rendered immediately before the server confirms them, hiding network latency.

Sessions continue running while disconnected. Each session runs in its own isolated host process, so sessions even survive agent restarts. Reconnecting picks up right where you left off, even if the session produced output in the meantime.

## Smart notifications

The agent uses AI to understand what's happening in your sessions and notify you when it matters.

### Session topics

Each session gets a rolling AI-generated label describing what it's doing — "Building project for macOS", "Editing nginx config", "Running test suite". Topics appear in the app's session list and update as your work evolves.

On macOS with Apple Intelligence (macOS 26+), topics are generated on-device with no configuration needed. On Linux, or for cloud-based processing, configure an AI provider in settings (Anthropic, OpenAI, or Gemini) or let the relay handle it.

### Push notifications

When you disconnect or background the app, the agent monitors your sessions and delivers push notifications to your device:

- **Bell** — immediate notification when a terminal bell fires (e.g. a build script calling `\a` on completion)
- **App-defined** — programs can send custom notifications with title and body via OSC escape sequences
- **AI summary** — when a session goes idle after producing new output, AI evaluates whether you should be notified. Completions ("Build succeeded"), failures ("Tests failed with 3 errors"), and prompts waiting for input all trigger a concise, natural-language notification. Routine output and idle sessions are silently ignored.

Push notifications are delivered through a relay server at `relay.evershell.app` and require no configuration beyond the defaults. The relay handles Apple Push Notification Service (APNs) delivery and, if no local AI provider is configured, AI summarization as well.

## App features

- **Native scrollback** — server-maintained scrollback rendered as native content with pixel-smooth scrolling and natural gestures
- **Search** — full-text search across the screen and entire scrollback history
- **Clipboard sync** — remote programs can copy to your device clipboard via OSC 52 (e.g. `pbcopy`, `xclip`)
- **URL detection** — clickable links in terminal output, with long-press to copy
- **Mouse support** — TUI apps that use mouse tracking (vim, htop, etc.) work natively with taps and gestures
- **Session previews** — thumbnail grid showing all sessions at a glance, with unread indicators
- **Themes and fonts** — 11 built-in color themes, custom theme editor, and full system monospace font selection
- **Pinch to zoom** — adjust font size with a pinch gesture on iOS

## Why not tmux + mosh?

tmux and mosh are excellent tools, but combining them has trade-offs. tmux manages sessions and mosh handles latency, but scrollback requires workarounds — tmux's scrollback is its own buffer that doesn't integrate with your terminal's native scroll, so you lose natural gestures like trackpad flicking or pixel-smooth scrolling on mobile.

evershell is built for this specific use case. The server maintains scrollback and streams it to the client as native content, so you get real scrollback with the scrolling behaviour your device expects. No configuration, no pairing two tools together, no scrollback hacks.

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

# Logs
journalctl --user -u evershell-agent -f
```

## Updating

Re-run the install script — it stops the service, replaces the binary, and restarts.

```bash
curl -fsSL https://raw.githubusercontent.com/oviano/evershell/main/install.sh | bash
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
curl -fsSL https://raw.githubusercontent.com/oviano/evershell/main/uninstall.sh | bash
```

Stops the service and removes the binary, settings, token, and TLS certificates.

## Configuration

Settings are in `settings.json`:

| Platform | Path |
|----------|------|
| macOS | `~/Library/Application Support/evershell/evershell-agent/settings.json` |
| Linux | `~/.config/evershell/evershell-agent/settings.json` |

On first run, default settings are copied to this location.

| Setting | Default | Description |
|---------|---------|-------------|
| `bind_address` | `0.0.0.0` | Listen address |
| `bind_port` | `8025` | Listen port |
| `enable_token_auth` | `true` | Require token authentication |
| `enable_tls` | `true` | TLS/DTLS encryption |
| `verbosity` | `1` | Log level: 0 = error, 1 = info, 2 = debug |
| `log_to_file` | `true` | Write to log file |
| `log_to_stdout` | `false` | Write to stdout |
| `push_notifications.enabled` | `true` | Enable push notifications |
| `push_notifications.relay_url` | `https://relay.evershell.app` | Relay server for push delivery |
| `push_notifications.quiescence_timeout` | `30` | Seconds of idle before AI evaluates a session |

Restart the service after changing settings.

### AI provider configuration

By default, the relay handles AI processing for both session topics and notifications. To run AI locally instead, add a provider configuration under `push_notifications`:

```json
{
    "push_notifications": {
        "topic": {
            "provider": "anthropic",
            "api_key": "sk-ant-...",
            "model": "claude-haiku-4-5-20251001"
        },
        "notifications": {
            "provider": "anthropic",
            "api_key": "sk-ant-...",
            "model": "claude-haiku-4-5-20251001"
        }
    }
}
```

Supported providers: `anthropic`, `openai`, `gemini`. On macOS with Apple Intelligence (macOS 26+), the `native` provider is auto-detected for topics and requires no API key.

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

**No push notifications** — Ensure notifications are enabled in the iOS/macOS system settings for the evershell app. The agent needs outbound HTTPS access to `relay.evershell.app` on port 443.

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
