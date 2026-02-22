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

- macOS
- [SwiftBar](https://github.com/swiftbar/SwiftBar)
- bash (3.x or later — the macOS default)
- `jq` (optional — for automatic hooks merging)

## Installation

### Via Homebrew (Recommended)

```bash
# Install SwiftBar if not already installed
brew install --cask swiftbar

# Install claude-menubar
brew tap emreboga/tools
brew install claude-menubar

# Run setup (auto-detects your terminal)
claude-menubar-setup
```

### Manual Installation

```bash
git clone https://github.com/emreboga/claude-menubar.git
cd claude-menubar
bash setup.sh
```

### After Installation

1. **Start SwiftBar** if not running
2. **Restart Claude Code** to load the hooks
3. You should see a dashed circle (⊙) in your menubar

### Supported Terminals

Terminal is auto-detected from `TERM_PROGRAM`. You can override with:

```bash
claude-menubar-setup --terminal Warp
```

Supported: `Terminal`, `iTerm`, `iTerm2`, `Warp`, `Alacritty`, `kitty`, `Hyper`, `WezTerm`, `Ghostty`

## Uninstallation

### Via Homebrew

```bash
claude-menubar-uninstall
brew uninstall claude-menubar
brew untap emreboga/tools
```

### Manual

```bash
bash uninstall.sh
```

This removes `~/.claude-menubar`. You may also need to remove Claude Code hooks from `~/.claude/settings.json` manually.

## Directory Structure

```
setup.sh                      Setup script
uninstall.sh                  Uninstall script
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
  "id":       "<12-char sha256 hash of repo path>",
  "repo":     "<basename>",
  "path":     "<full path>",
  "state":    "idle|busy|waiting|error",
  "message":  "<description>",
  "terminal": "<detected terminal app>",
  "pid":      12345,
  "ts":       1700000000
}
```

## Claude Code Hooks

The following hooks are configured automatically by `setup.sh`:

| Hook           | Action                                |
|----------------|---------------------------------------|
| `SessionStart` | Set state → **busy**                  |
| `Notification` | Set state → **waiting** + macOS alert |
| `Stop`         | Set state → **idle**                  |

## Session Management

- **Click a repo name** in the dropdown to focus that terminal window.
- **Clear ALL** removes all status files immediately.
- Status files older than **24 hours** are auto-deleted on each plugin refresh.
- Sessions that stay busy or waiting for **10 minutes** without an update are automatically marked stale (🔴).

## Running Tests

```bash
bash tests/test-cc-status.sh
```

## TODO

- [ ] **Tab-level focusing**: When clicking a session, focus the exact window/tab where Claude Code is running (not just the terminal app). iTerm2 supports this via `$ITERM_SESSION_ID`. Warp and other terminals need investigation.
