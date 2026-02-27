# Privacy Policy

**Evershell** is a terminal client that connects directly to agents you install on your own machines. There is no intermediary service.

## Data We Collect

None. Evershell does not collect, transmit, or store any personal data, usage analytics, crash reports, or telemetry.

## Data Stored on Your Device

- **Agent configurations** (hostname, port, display name) are synced via iCloud Key-Value Storage, an Apple service subject to Apple's privacy policy.
- **Authentication tokens** are stored in the iOS/macOS Keychain.
- **Tab state** (which sessions were open) is stored locally in UserDefaults for session restore.

All of this data stays on your device and your iCloud account. We have no access to it.

## Network Connections

The app connects only to agent addresses you configure. All connections use TLS/DTLS encryption. No data is sent to us or any third party.

## Third-Party Services

Evershell includes open-source libraries (terminal emulation, compression, cryptography) compiled into the app. None of these collect data or make network connections. There are no analytics, advertising, or tracking services.

## Contact

If you have questions about this policy, open an issue at [github.com/oviano/evershell-agent](https://github.com/oviano/evershell-agent).
