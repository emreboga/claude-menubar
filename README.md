# claude-menubar

A macOS [SwiftBar](https://github.com/swiftbar/SwiftBar) plugin that monitors Claude Code sessions and displays their status in the menubar using colored dots.

## Menubar Display

| Dot | State   | Meaning                        |
|-----|---------|--------------------------------|
| 🟢  | idle    | Session is idle / task done    |
| 🟡  | busy    | Claude is working              |
| 🟣  | waiting | Needs your input/permission    |
| 🔴  | error / stale | Error or inactive 10+ min |
| ⊙   | —       | No active sessions             |

Multiple sessions show multiple dots sorted by repository name.

## Requirements

- macOS with [SwiftBar](https://github.com/swiftbar/SwiftBar) installed
- bash (3.x or later — the macOS default)
- `jq` (optional — only needed for automatic hooks merging during install)

## Installation

```bash
bash install.sh --terminal Warp
```

Then symlink the plugin into your SwiftBar plugins folder:

```bash
ln -s ~/.claude-menubar/bin/claude-menubar.10s.sh \
      ~/Library/Application\ Support/SwiftBar/Plugins/
```

Restart Claude Code to pick up the new hooks.

### Supported terminals

`Terminal` (default), `iTerm`, `iTerm2`, `Warp`, `Alacritty`, `kitty`, `Hyper`, `WezTerm`, `Ghostty`

## Uninstallation

```bash
bash uninstall.sh
```

This removes `~/.claude-menubar`. Remove any SwiftBar symlink and Claude Code hooks manually.

## Directory Structure

```
install.sh                    Installer
uninstall.sh                  Uninstaller
lib/common.sh                 Shared bash functions
scripts/cc-status             CLI: set/clear session status
scripts/claude-menubar.10s.sh SwiftBar plugin (10 s refresh)
scripts/clear-all             Remove all status files
scripts/focus-terminal        Activate terminal app via AppleScript
config/claude-hooks.json      Claude Code hooks template
tests/test-cc-status.sh       Test suite
```

Runtime files are installed to `~/.claude-menubar/`:

```
config.json     Terminal preference
bin/            Installed scripts
lib/            Shared functions
status/         Per-session JSON status files
logs/           Session logs (rotated at 100 KB)
```

## Status JSON Format

```json
{
  "id":      "<12-char sha256 hash of repo path>",
  "repo":    "<basename>",
  "path":    "<full path>",
  "state":   "idle|busy|waiting|error",
  "message": "<description>",
  "pid":     12345,
  "ts":      1700000000
}
```

## Claude Code Hooks

The following hooks are configured automatically by `install.sh`:

| Hook               | Action                                |
|--------------------|---------------------------------------|
| `SessionStart`     | Set state → **busy**                  |
| `Notification`     | Set state → **waiting** + macOS alert |
| `PermissionRequest`| Set state → **waiting** + macOS alert |
| `TaskCompleted`    | Set state → **idle**                  |
| `Stop`             | Set state → **idle**                  |
| `PostToolUseFailure` | Set state → **error**              |

## Session Management

- **Click a repo name** in the dropdown to focus that terminal window.
- **Clear ALL** removes all status files immediately.
- Status files older than **24 hours** are auto-deleted on each plugin refresh.
- Sessions that stay busy or waiting for **10 minutes** without an update are automatically marked stale (🔴).

## Running Tests

```bash
bash tests/test-cc-status.sh
```