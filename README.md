# claude-menubar

A macOS [SwiftBar](https://github.com/swiftbar/SwiftBar) plugin that monitors Claude Code sessions and displays their status in the menubar.

| Dot | State         | Meaning                     |
|-----|---------------|-----------------------------|
| 🟢  | idle          | Session idle / task done     |
| 🟡  | busy          | Claude is working            |
| 🟣  | waiting       | Needs your input/permission  |
| 🔴  | error / stale | Error or inactive 10+ min    |
| ⊙   | —             | No active sessions           |

Multiple sessions show multiple dots sorted by repository name.

## Installation

### Via Homebrew (Recommended)

```bash
brew install --cask swiftbar
brew tap emreboga/tools
brew install claude-menubar
claude-menubar-setup
```

### Manual

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

Terminal is auto-detected from `TERM_PROGRAM`. Override with:

```bash
claude-menubar-setup --terminal Warp
```

Supported: `Terminal`, `iTerm`, `iTerm2`, `Warp`, `Alacritty`, `kitty`, `Hyper`, `WezTerm`, `Ghostty`

## How It Works

Claude Code hooks (configured automatically by `setup.sh`) call `cc-status` to write session state to `~/.claude-menubar/status/`. SwiftBar reads these files every 5 seconds and renders the menubar.

| Hook           | Action                                |
|----------------|---------------------------------------|
| `SessionStart` | Set state → **busy**                  |
| `Notification` | Set state → **waiting** + macOS alert |
| `Stop`         | Set state → **idle**                  |

- **Click a session** to focus its terminal window and clear its status.
- **Clear ALL** removes all status files immediately.
- Sessions busy/waiting for **10+ minutes** are marked stale (🔴).
- Status files older than **24 hours** are auto-deleted.

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

Hooks in `~/.claude/settings.json` are also removed (requires `jq`).

## TODO

- [ ] **Tab-level focusing**: Focus the exact terminal tab where Claude Code is running (not just the app). iTerm2 supports this via `$ITERM_SESSION_ID`.
