#!/usr/bin/env bash
# common.sh - Shared functions for claude-menubar
#
# Provides: JSON helpers, state colors/dots, repo ID hashing,
# status file I/O, and logging.

# ---------------------------------------------------------------------------
# Base paths (can be overridden for testing)
# ---------------------------------------------------------------------------
CLAUDE_MENUBAR_DIR="${CLAUDE_MENUBAR_DIR:-${HOME}/.claude-menubar}"
STATUS_DIR="${STATUS_DIR:-${CLAUDE_MENUBAR_DIR}/status}"
LOG_DIR="${LOG_DIR:-${CLAUDE_MENUBAR_DIR}/logs}"
CONFIG_FILE="${CONFIG_FILE:-${CLAUDE_MENUBAR_DIR}/config.json}"

# ---------------------------------------------------------------------------
# Repo ID: first 12 hex chars of SHA-256 of the repo path
# Supports both macOS (shasum) and Linux (sha256sum).
# ---------------------------------------------------------------------------
get_repo_id() {
  local path="${1}"
  if command -v shasum &>/dev/null; then
    printf '%s' "${path}" | shasum -a 256 | cut -c1-12
  elif command -v sha256sum &>/dev/null; then
    printf '%s' "${path}" | sha256sum | cut -c1-12
  else
    # Fallback: md5 is NOT cryptographically secure, but is only used here
    # as a non-security-sensitive session identifier when SHA-256 tools are
    # unavailable. The ID is never used for authentication or access control.
    printf '%s' "${path}" | md5sum | cut -c1-12
  fi
}

# ---------------------------------------------------------------------------
# State → emoji dot
# ---------------------------------------------------------------------------
state_dot() {
  local state="${1}"
  case "${state}" in
    idle)    printf '🟢' ;;
    busy)    printf '🟡' ;;
    waiting) printf '🟣' ;;
    error)   printf '🔴' ;;
    stale)   printf '🔴' ;;
    *)       printf '⚪' ;;
  esac
}

# ---------------------------------------------------------------------------
# State → hex color (for SwiftBar color= param)
# ---------------------------------------------------------------------------
state_color() {
  local state="${1}"
  case "${state}" in
    idle)    printf '#22c55e' ;;
    busy)    printf '#eab308' ;;
    waiting) printf '#a855f7' ;;
    error)   printf '#ef4444' ;;
    stale)   printf '#ef4444' ;;
    *)       printf '#6b7280' ;;
  esac
}

# ---------------------------------------------------------------------------
# JSON helpers (no jq required)
# ---------------------------------------------------------------------------

# Escape a string for use as a JSON string value.
json_escape() {
  local str="${1}"
  str="${str//\\/\\\\}"   # backslashes first
  str="${str//\"/\\\"}"   # double-quotes
  str="${str//$'\n'/\\n}" # newlines
  str="${str//$'\t'/\\t}" # tabs
  str="${str//$'\r'/\\r}" # carriage returns
  printf '%s' "${str}"
}

# Extract a JSON string field (no jq required).
# Usage: json_get '{"key":"value"}' key
json_get() {
  local json="${1}"
  local field="${2}"
  printf '%s' "${json}" \
    | grep -o "\"${field}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" \
    | sed 's/.*:[[:space:]]*"\(.*\)"/\1/' \
    | head -1
}

# Extract a JSON numeric field.
json_get_num() {
  local json="${1}"
  local field="${2}"
  printf '%s' "${json}" \
    | grep -o "\"${field}\"[[:space:]]*:[[:space:]]*[0-9][0-9]*" \
    | sed 's/.*:[[:space:]]*//' \
    | head -1
}

# ---------------------------------------------------------------------------
# Status file I/O
# ---------------------------------------------------------------------------

# Write a session status JSON file.
write_status() {
  local id="${1}"
  local repo="${2}"
  local path="${3}"
  local state="${4}"
  local message="${5:-}"
  local pid="${6:-$$}"
  local ts
  ts=$(date +%s)

  mkdir -p "${STATUS_DIR}"

  local repo_esc path_esc msg_esc
  repo_esc=$(json_escape "${repo}")
  path_esc=$(json_escape "${path}")
  msg_esc=$(json_escape "${message}")

  cat > "${STATUS_DIR}/${id}.json" <<EOF
{
  "id": "${id}",
  "repo": "${repo_esc}",
  "path": "${path_esc}",
  "state": "${state}",
  "message": "${msg_esc}",
  "pid": ${pid},
  "ts": ${ts}
}
EOF
}

# ---------------------------------------------------------------------------
# Config helpers
# ---------------------------------------------------------------------------

# Read the configured terminal application from config.json.
get_terminal() {
  if [[ -f "${CONFIG_FILE}" ]]; then
    local terminal
    terminal=$(json_get "$(cat "${CONFIG_FILE}")" "terminal")
    if [[ -n "${terminal}" ]]; then
      printf '%s' "${terminal}"
      return
    fi
  fi
  printf 'Terminal'
}

# ---------------------------------------------------------------------------
# Logging (100 KB rotation)
# ---------------------------------------------------------------------------

log_message() {
  local session_id="${1}"
  local message="${2}"

  mkdir -p "${LOG_DIR}"
  local log_file="${LOG_DIR}/${session_id}.log"

  # Rotate if the log exceeds 100 KB
  if [[ -f "${log_file}" ]] && [[ $(wc -c < "${log_file}") -gt 102400 ]]; then
    mv "${log_file}" "${log_file}.old"
  fi

  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "${message}" >> "${log_file}"
}
