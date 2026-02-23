#!/usr/bin/env bash
# uninstall.sh - Remove the claude-menubar installation

set -euo pipefail

INSTALL_DIR="${HOME}/.claude-menubar"

printf 'Uninstalling claude-menubar...\n'

if [[ -d "${INSTALL_DIR}" ]]; then
  rm -rf "${INSTALL_DIR}"
  printf 'Removed %s\n' "${INSTALL_DIR}"
else
  printf '%s not found — nothing to remove.\n' "${INSTALL_DIR}"
fi

SWIFTBAR_PLUGINS="${HOME}/Library/Application Support/SwiftBar/Plugins"
PLUGIN_LINK="${SWIFTBAR_PLUGINS}/claude-menubar.5s.sh"

if [[ -L "${PLUGIN_LINK}" ]]; then
  rm -f "${PLUGIN_LINK}"
  printf 'Removed SwiftBar plugin symlink\n'
fi

printf '\nNOTE: Hooks in ~/.claude/settings.json were NOT removed.\n'
printf 'Remove them manually if they are no longer needed.\n'
