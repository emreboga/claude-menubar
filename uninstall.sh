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

printf '\nNOTE: Hooks in ~/.claude/settings.json were NOT removed.\n'
printf 'Remove them manually if they are no longer needed.\n\n'
printf 'Also remove any SwiftBar plugin symlink you created.\n'
