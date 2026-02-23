# claude-menubar

## Architecture

```
Claude Code Hook → cc-status CLI → writes JSON → SwiftBar reads every 5s → menubar updates
```

### Key Components

| File | Purpose |
|------|---------|
| `scripts/cc-status` | CLI for setting/clearing session status. Called by Claude Code hooks |
| `scripts/claude-menubar.5s.sh` | SwiftBar plugin. Reads status files, renders menubar |
| `scripts/focus-terminal` | AppleScript wrapper to activate terminal apps. Clears session status on click |
| `scripts/clear-all` | Removes all status files |
| `lib/common.sh` | Shared bash functions: JSON helpers, state colors, terminal detection, status I/O |
| `config/claude-hooks.json` | Hook definitions merged into `~/.claude/settings.json` |
| `setup.sh` | Installs to `~/.claude-menubar`, merges hooks, creates SwiftBar symlink |
| `uninstall.sh` | Removes `~/.claude-menubar` and SwiftBar symlink |

### Runtime Directory (`~/.claude-menubar/`)

- `status/*.json` — Per-session status files (keyed by 12-char SHA256 of repo path)
- `logs/*.log` — Session logs (100KB rotation)
- `config.json` — User config (terminal app)
- `bin/`, `lib/` — Installed scripts

### Status JSON

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

### Claude Code Hooks

Hook structure in `~/.claude/settings.json`:
```json
{
  "hooks": {
    "SessionStart": [{ "hooks": [{ "type": "command", "command": "~/.claude-menubar/bin/cc-status set busy 'Session started'" }] }],
    "Notification": [{ "hooks": [{ "type": "command", "command": "~/.claude-menubar/bin/cc-status notify" }] }],
    "Stop":         [{ "hooks": [{ "type": "command", "command": "~/.claude-menubar/bin/cc-status set idle 'Session stopped'" }] }]
  }
}
```

## Homebrew Distribution

Distributed via `emreboga/homebrew-tools` tap. The formula installs source to Homebrew's pkgshare and creates wrapper scripts (`claude-menubar-setup`, `claude-menubar-uninstall`). User runs `claude-menubar-setup` after install.

## Development Notes

- **Bash 3 compatible** — indexed arrays only, no associative arrays
- **No jq at runtime** — JSON parsing via grep/sed (jq only for install-time hook merging)
- **5-second refresh** — set by plugin filename (`*.5s.sh`)
- **Stale detection** — sessions busy/waiting >10 min marked stale
- **Auto-cleanup** — status files >24 hours old are deleted
- **Click to clear** — clicking a session removes its status file and refreshes the menubar
