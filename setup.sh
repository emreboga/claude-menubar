#!/usr/bin/env bash
# setup.sh - Set up claude-menubar in ~/.claude-menubar
#
# Usage: bash setup.sh [--terminal <app>]
#
# Supported terminals: Terminal (default), iTerm, iTerm2, Warp, Alacritty,
#                      kitty, Hyper, WezTerm, Ghostty

set -euo pipefail

INSTALL_DIR="${HOME}/.claude-menubar"
CLAUDE_SETTINGS="${HOME}/.claude/settings.json"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TERMINAL="Terminal"

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "${1}" in
    --terminal)
      TERMINAL="${2}"
      shift 2
      ;;
    -h|--help)
      cat <<'EOF'
Usage: claude-menubar-setup [--terminal <app>]

Options:
  --terminal <app>   Terminal to use for session focus (default: auto-detected)
                     Supported: Terminal, iTerm, iTerm2, Warp, Alacritty,
                                kitty, Hyper, WezTerm, Ghostty
EOF
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "${1}" >&2
      exit 1
      ;;
  esac
done

printf 'Setting up claude-menubar in %s ...\n' "${INSTALL_DIR}"

# ---------------------------------------------------------------------------
# Create directory structure
# ---------------------------------------------------------------------------
mkdir -p "${INSTALL_DIR}/bin"
mkdir -p "${INSTALL_DIR}/lib"
mkdir -p "${INSTALL_DIR}/status"
mkdir -p "${INSTALL_DIR}/logs"

# ---------------------------------------------------------------------------
# Copy files
# ---------------------------------------------------------------------------
cp "${SOURCE_DIR}/lib/common.sh" "${INSTALL_DIR}/lib/common.sh"

cp "${SOURCE_DIR}/scripts/cc-status"              "${INSTALL_DIR}/bin/cc-status"
cp "${SOURCE_DIR}/scripts/claude-menubar.10s.sh"  "${INSTALL_DIR}/bin/claude-menubar.10s.sh"
cp "${SOURCE_DIR}/scripts/clear-all"              "${INSTALL_DIR}/bin/clear-all"
cp "${SOURCE_DIR}/scripts/focus-terminal"         "${INSTALL_DIR}/bin/focus-terminal"

chmod +x "${INSTALL_DIR}/bin/"*

# ---------------------------------------------------------------------------
# Write config.json (preserve existing terminal choice if already configured)
# ---------------------------------------------------------------------------
if [[ ! -f "${INSTALL_DIR}/config.json" ]]; then
  cat > "${INSTALL_DIR}/config.json" <<EOF
{
  "terminal": "${TERMINAL}"
}
EOF
  printf 'Configured terminal: %s\n' "${TERMINAL}"
else
  printf 'Keeping existing config.json (terminal already configured)\n'
fi

# ---------------------------------------------------------------------------
# Merge hooks into ~/.claude/settings.json
# ---------------------------------------------------------------------------
merge_hooks() {
  mkdir -p "${HOME}/.claude"

  if [[ ! -f "${CLAUDE_SETTINGS}" ]]; then
    cp "${SOURCE_DIR}/config/claude-hooks.json" "${CLAUDE_SETTINGS}"
    printf 'Created %s with hooks\n' "${CLAUDE_SETTINGS}"
    return
  fi

  if command -v jq &>/dev/null; then
    local hooks_json existing merged
    hooks_json=$(jq '.hooks' "${SOURCE_DIR}/config/claude-hooks.json")
    existing=$(cat "${CLAUDE_SETTINGS}")
    # Use + to merge hook keys: our keys take precedence over existing ones.
    # Top-level keys not in our template are preserved.
    merged=$(printf '%s' "${existing}" \
      | jq --argjson h "${hooks_json}" '.hooks = ((.hooks // {}) + $h)')
    printf '%s\n' "${merged}" > "${CLAUDE_SETTINGS}"
    printf 'Merged hooks into %s\n' "${CLAUDE_SETTINGS}"
  else
    printf 'WARNING: jq not found — hooks were NOT merged automatically.\n' >&2
    printf 'Please add hooks from %s/config/claude-hooks.json\n' "${SOURCE_DIR}" >&2
    printf 'to %s manually.\n' "${CLAUDE_SETTINGS}" >&2
  fi
}

merge_hooks

# ---------------------------------------------------------------------------
# Create SwiftBar plugin symlink
# ---------------------------------------------------------------------------
SWIFTBAR_PLUGINS="${HOME}/Library/Application Support/SwiftBar/Plugins"
mkdir -p "${SWIFTBAR_PLUGINS}"

PLUGIN_LINK="${SWIFTBAR_PLUGINS}/claude-menubar.10s.sh"
PLUGIN_TARGET="${INSTALL_DIR}/bin/claude-menubar.10s.sh"

if [[ -L "${PLUGIN_LINK}" ]]; then
  printf 'SwiftBar plugin symlink already exists\n'
elif [[ -e "${PLUGIN_LINK}" ]]; then
  printf 'WARNING: %s exists but is not a symlink\n' "${PLUGIN_LINK}" >&2
else
  ln -s "${PLUGIN_TARGET}" "${PLUGIN_LINK}"
  printf 'Created SwiftBar plugin symlink\n'
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
printf '\nSetup complete!\n\n'
printf 'Next steps:\n'
printf '  1. Install SwiftBar if not installed: brew install --cask swiftbar\n'
printf '  2. Restart Claude Code to load the hooks\n'
