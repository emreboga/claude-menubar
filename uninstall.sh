#!/usr/bin/env bash
# uninstall.sh - Remove the claude-menubar installation

set -euo pipefail

INSTALL_DIR="${HOME}/.claude-menubar"
CLAUDE_SETTINGS="${HOME}/.claude/settings.json"

printf 'Uninstalling claude-menubar...\n'

# ---------------------------------------------------------------------------
# Remove ~/.claude-menubar
# ---------------------------------------------------------------------------
if [[ -d "${INSTALL_DIR}" ]]; then
  rm -rf "${INSTALL_DIR}"
  printf 'Removed %s\n' "${INSTALL_DIR}"
else
  printf '%s not found — nothing to remove.\n' "${INSTALL_DIR}"
fi

# ---------------------------------------------------------------------------
# Remove SwiftBar plugin symlink
# ---------------------------------------------------------------------------
SWIFTBAR_PLUGINS="${HOME}/Library/Application Support/SwiftBar/Plugins"
PLUGIN_LINK="${SWIFTBAR_PLUGINS}/claude-menubar.5s.sh"

if [[ -L "${PLUGIN_LINK}" ]]; then
  rm -f "${PLUGIN_LINK}"
  printf 'Removed SwiftBar plugin symlink\n'
fi

# ---------------------------------------------------------------------------
# Remove hooks from ~/.claude/settings.json
# ---------------------------------------------------------------------------
if [[ -f "${CLAUDE_SETTINGS}" ]] && command -v jq &>/dev/null; then
  HOOK_KEYS=("SessionStart" "Notification" "Stop")
  updated=$(cat "${CLAUDE_SETTINGS}")

  for key in "${HOOK_KEYS[@]}"; do
    # Only remove the key if every command in it references cc-status
    has_ours=$(printf '%s' "${updated}" \
      | jq -e ".hooks.${key} // empty | .[].hooks[]
               | select(.command | contains(\"cc-status\"))" 2>/dev/null)
    has_others=$(printf '%s' "${updated}" \
      | jq -e ".hooks.${key} // empty | .[].hooks[]
               | select(.command | contains(\"cc-status\") | not)" 2>/dev/null)

    if [[ -n "${has_ours}" && -z "${has_others}" ]]; then
      updated=$(printf '%s' "${updated}" | jq "del(.hooks.${key})")
    fi
  done

  # Remove the hooks key entirely if it's now empty
  updated=$(printf '%s' "${updated}" \
    | jq 'if .hooks == {} then del(.hooks) else . end')

  printf '%s\n' "${updated}" > "${CLAUDE_SETTINGS}"
  printf 'Removed hooks from %s\n' "${CLAUDE_SETTINGS}"
elif [[ -f "${CLAUDE_SETTINGS}" ]]; then
  printf 'WARNING: jq not found — hooks in %s were NOT removed.\n' "${CLAUDE_SETTINGS}" >&2
  printf 'Remove SessionStart, Notification, and Stop hooks manually.\n' >&2
fi

printf '\nUninstall complete.\n'
