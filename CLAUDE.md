# Claude Code Context: claude-menubar

## Overview

A macOS SwiftBar plugin that displays Claude Code session status in the menubar. Shows colored dots indicating session state (busy, idle, waiting, error) and allows clicking to focus the terminal where the session is running.

## Architecture

```
Claude Code Hook → cc-status CLI → writes JSON → SwiftBar reads → menubar updates
```

### Key Components

| File | Purpose |
|------|---------|
| `lib/common.sh` | Shared bash functions: JSON helpers, state colors, terminal detection, status I/O |
| `scripts/cc-status` | CLI for setting/clearing session status. Called by Claude Code hooks |
| `scripts/claude-menubar.5s.sh` | SwiftBar plugin that runs every 5s, reads status files, renders menubar |
| `scripts/focus-terminal` | AppleScript wrapper to activate terminal apps |
| `scripts/clear-all` | Removes all status files |
| `config/claude-hooks.json` | Hook definitions merged into ~/.claude/settings.json |
| `setup.sh` | Installs to ~/.claude-menubar, merges hooks |
| `unsetup.sh` | Removes ~/.claude-menubar |

### Runtime Directories

All runtime files are in `~/.claude-menubar/`:
- `status/*.json` - Per-session status files (keyed by 12-char SHA256 of repo path)
- `logs/*.log` - Session logs (100KB rotation)
- `config.json` - User preferences (terminal app)
- `bin/`, `lib/` - Installed scripts

### Status JSON Structure

```json
{
  "id": "a1b2c3d4e5f6",
  "repo": "my-project",
  "path": "/Users/emre/my-project",
  "state": "busy",
  "message": "Working...",
  "terminal": "Warp",
  "pid": 12345,
  "ts": 1700000000
}
```

### Terminal Detection

Terminal app is auto-detected from `TERM_PROGRAM` env var:
- `WarpTerminal` → Warp
- `Apple_Terminal` → Terminal
- `iTerm.app` → iTerm2
- `vscode` → VSCode
- etc.

### Claude Code Hooks

Configured in `~/.claude/settings.json`:
- `SessionStart` → sets state to "busy"
- `Notification` → sets state to "waiting" + macOS notification
- `Stop` → sets state to "idle"

Hook structure requires nested `hooks` array:
```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          { "type": "command", "command": "~/.claude-menubar/bin/cc-status set busy" }
        ]
      }
    ]
  }
}
```

## Homebrew Distribution

Distributed via `emreboga/homebrew-tools` tap:
```sh
brew tap emreboga/tools
brew install claude-menubar
```

The formula:
1. Installs source to Homebrew's pkgshare
2. Auto-runs setup.sh during brew install
3. Creates SwiftBar plugins directory and symlinks plugin

## Development Notes

- **Bash 3 compatible**: Uses indexed arrays, no associative arrays
- **No jq at runtime**: JSON parsing via grep/sed (jq only for install-time hook merging)
- **5-second refresh**: Plugin filename `*.5s.sh` sets SwiftBar refresh interval
- **Stale detection**: Sessions busy/waiting >10 min marked as stale (red dot)
- **Auto-cleanup**: Status files >24 hours old are deleted

## Known Limitations

- Tab-level focusing not implemented (TODO in README)
- Some hook types (TaskCompleted, PermissionRequest, PostToolUseFailure) not yet supported by Claude Code
