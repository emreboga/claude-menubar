#!/usr/bin/env bash
# <xbar.title>Claude Code Status</xbar.title>
# <xbar.version>v1.0</xbar.version>
# <xbar.author>claude-menubar</xbar.author>
# <xbar.author.github>emreboga</xbar.author.github>
# <xbar.desc>Monitor Claude Code session status in the menubar.</xbar.desc>
# <xbar.hideAbout>true</xbar.hideAbout>
# <xbar.hideRunInTerminal>true</xbar.hideRunInTerminal>
# <xbar.hideLastUpdated>true</xbar.hideLastUpdated>
# <xbar.hideDisablePlugin>true</xbar.hideDisablePlugin>
# <xbar.hideSwiftBar>false</xbar.hideSwiftBar>
#
# claude-menubar.5s.sh - SwiftBar plugin for Claude Code (refreshes every 5 s)

set -euo pipefail

CLAUDE_MENUBAR_DIR="${HOME}/.claude-menubar"
BIN_DIR="${CLAUDE_MENUBAR_DIR}/bin"
LIB_DIR="${CLAUDE_MENUBAR_DIR}/lib"

# If not installed, show a placeholder icon and exit.
if [[ ! -f "${LIB_DIR}/common.sh" ]]; then
  echo " | sfimage=circle.dashed"
  echo "---"
  echo "claude-menubar not installed"
  echo "Run install.sh to set up | color=#6b7280"
  exit 0
fi

# shellcheck source=/dev/null
source "${LIB_DIR}/common.sh"

STALE_THRESHOLD=600  # 10 minutes → mark busy/waiting as stale
MAX_AGE=86400        # 24 hours  → auto-delete old status files

NOW=$(date +%s)

# ---------------------------------------------------------------------------
# Auto-delete status files older than 24 hours
# ---------------------------------------------------------------------------
if [[ -d "${STATUS_DIR}" ]]; then
  for f in "${STATUS_DIR}"/*.json; do
    [[ -f "${f}" ]] || continue
    content=$(cat "${f}")
    ts=$(json_get_num "${content}" "ts")
    if [[ -n "${ts}" ]] && [[ $((NOW - ts)) -gt ${MAX_AGE} ]]; then
      rm -f "${f}"
    fi
  done
fi

# ---------------------------------------------------------------------------
# Collect sessions (bash-3-compatible indexed arrays)
# ---------------------------------------------------------------------------
ALL_IDS=()
ALL_REPOS=()
ALL_PATHS=()
ALL_STATES=()
ALL_MESSAGES=()
ALL_TERMINALS=()
ALL_TSS=()

if [[ -d "${STATUS_DIR}" ]]; then
  for f in "${STATUS_DIR}"/*.json; do
    [[ -f "${f}" ]] || continue
    content=$(cat "${f}")
    id=$(json_get "${content}" "id")
    repo=$(json_get "${content}" "repo")
    path=$(json_get "${content}" "path")
    state=$(json_get "${content}" "state")
    message=$(json_get "${content}" "message")
    terminal=$(json_get "${content}" "terminal")
    ts=$(json_get_num "${content}" "ts")

    # Mark as stale if busy/waiting and inactive for ≥ 10 minutes
    if [[ -n "${ts}" ]] && [[ $((NOW - ts)) -gt ${STALE_THRESHOLD} ]]; then
      if [[ "${state}" == "busy" || "${state}" == "waiting" ]]; then
        state="stale"
      fi
    fi

    # Fallback to configured terminal if not stored in session
    if [[ -z "${terminal}" ]]; then
      terminal=$(get_terminal)
    fi

    ALL_IDS[${#ALL_IDS[@]}]="${id}"
    ALL_REPOS[${#ALL_REPOS[@]}]="${repo}"
    ALL_PATHS[${#ALL_PATHS[@]}]="${path}"
    ALL_STATES[${#ALL_STATES[@]}]="${state}"
    ALL_MESSAGES[${#ALL_MESSAGES[@]}]="${message}"
    ALL_TERMINALS[${#ALL_TERMINALS[@]}]="${terminal}"
    ALL_TSS[${#ALL_TSS[@]}]="${ts}"
  done
fi

# ---------------------------------------------------------------------------
# Sort sessions by repo name (bubble sort — bash-3-compatible)
# ---------------------------------------------------------------------------
COUNT=${#ALL_REPOS[@]}
if [[ ${COUNT} -gt 1 ]]; then
  for ((i = 0; i < COUNT - 1; i++)); do
    for ((j = 0; j < COUNT - i - 1; j++)); do
      if [[ "${ALL_REPOS[$j]}" > "${ALL_REPOS[$((j + 1))]}" ]]; then
        tmp="${ALL_REPOS[$j]}";     ALL_REPOS[$j]="${ALL_REPOS[$((j+1))]}";     ALL_REPOS[$((j+1))]="${tmp}"
        tmp="${ALL_STATES[$j]}";    ALL_STATES[$j]="${ALL_STATES[$((j+1))]}";    ALL_STATES[$((j+1))]="${tmp}"
        tmp="${ALL_PATHS[$j]}";     ALL_PATHS[$j]="${ALL_PATHS[$((j+1))]}";     ALL_PATHS[$((j+1))]="${tmp}"
        tmp="${ALL_MESSAGES[$j]}";  ALL_MESSAGES[$j]="${ALL_MESSAGES[$((j+1))]}"; ALL_MESSAGES[$((j+1))]="${tmp}"
        tmp="${ALL_TERMINALS[$j]}"; ALL_TERMINALS[$j]="${ALL_TERMINALS[$((j+1))]}"; ALL_TERMINALS[$((j+1))]="${tmp}"
        tmp="${ALL_IDS[$j]}";       ALL_IDS[$j]="${ALL_IDS[$((j+1))]}";         ALL_IDS[$((j+1))]="${tmp}"
        tmp="${ALL_TSS[$j]}";       ALL_TSS[$j]="${ALL_TSS[$((j+1))]}";         ALL_TSS[$((j+1))]="${tmp}"
      fi
    done
  done
fi

# ---------------------------------------------------------------------------
# Menubar title line
# ---------------------------------------------------------------------------
if [[ ${COUNT} -eq 0 ]]; then
  echo " | sfimage=circle.dashed"
else
  DOTS=""
  for ((i = 0; i < COUNT; i++)); do
    dot=$(state_dot "${ALL_STATES[$i]}")
    if [[ -z "${DOTS}" ]]; then
      DOTS="${dot}"
    else
      DOTS="${DOTS} ${dot}"
    fi
  done
  echo "${DOTS}"
fi

echo "---"

# ---------------------------------------------------------------------------
# Dropdown: one entry per session
# ---------------------------------------------------------------------------
if [[ ${COUNT} -eq 0 ]]; then
  echo "No active Claude Code sessions | color=#6b7280"
else
  for ((i = 0; i < COUNT; i++)); do
    repo="${ALL_REPOS[$i]}"
    state="${ALL_STATES[$i]}"
    path="${ALL_PATHS[$i]}"
    message="${ALL_MESSAGES[$i]}"
    terminal="${ALL_TERMINALS[$i]}"
    dot=$(state_dot "${state}")
    color=$(state_color "${state}")
    id="${ALL_IDS[$i]}"
    echo "${dot} ${repo} (${state}) | bash=${BIN_DIR}/focus-terminal param1=${terminal} param2=${path} param3=${id} terminal=false refresh=true color=${color}"
    if [[ -n "${message}" ]]; then
      echo "  ↳ ${message} | color=${color} size=11"
    fi
  done
fi

echo "---"
echo "Clear | bash=${BIN_DIR}/clear-all terminal=false refresh=true"
echo "Refresh | refresh=true"
