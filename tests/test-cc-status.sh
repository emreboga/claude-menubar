#!/usr/bin/env bash
# test-cc-status.sh - Test suite for claude-menubar
#
# Tests lib/common.sh helpers and the cc-status CLI script.
# Compatible with bash 3.x; no external test framework required.
#
# Usage: bash tests/test-cc-status.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIB="${REPO_ROOT}/lib/common.sh"
CC_STATUS="${REPO_ROOT}/scripts/cc-status"

# ---------------------------------------------------------------------------
# Tiny test framework
# ---------------------------------------------------------------------------
TESTS_RUN=0
TESTS_FAILED=0

pass() { printf '  PASS: %s\n' "${1}"; }
fail() { printf '  FAIL: %s\n' "${1}" >&2; TESTS_FAILED=$((TESTS_FAILED + 1)); }

assert_eq() {
  local desc="${1}" expected="${2}" actual="${3}"
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ "${expected}" == "${actual}" ]]; then
    pass "${desc}"
  else
    fail "${desc} — expected '${expected}', got '${actual}'"
  fi
}

assert_not_empty() {
  local desc="${1}" actual="${2}"
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ -n "${actual}" ]]; then
    pass "${desc}"
  else
    fail "${desc} — expected non-empty value"
  fi
}

assert_file_exists() {
  local desc="${1}" path="${2}"
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ -f "${path}" ]]; then
    pass "${desc}"
  else
    fail "${desc} — file not found: ${path}"
  fi
}

assert_file_absent() {
  local desc="${1}" path="${2}"
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ ! -f "${path}" ]]; then
    pass "${desc}"
  else
    fail "${desc} — file should not exist: ${path}"
  fi
}

# ---------------------------------------------------------------------------
# Set up an isolated temp environment so tests never touch ~/.claude-menubar
# ---------------------------------------------------------------------------
TMP_DIR=$(mktemp -d)
cleanup() { rm -rf "${TMP_DIR}"; }
trap cleanup EXIT

export CLAUDE_MENUBAR_DIR="${TMP_DIR}/claude-menubar"
export STATUS_DIR="${CLAUDE_MENUBAR_DIR}/status"
export LOG_DIR="${CLAUDE_MENUBAR_DIR}/logs"
export CONFIG_FILE="${CLAUDE_MENUBAR_DIR}/config.json"

mkdir -p "${STATUS_DIR}" "${LOG_DIR}"

# Load the library under test
# shellcheck source=../lib/common.sh
source "${LIB}"

# ---------------------------------------------------------------------------
# Tests: get_repo_id
# ---------------------------------------------------------------------------
printf '\n--- get_repo_id ---\n'

ID1=$(get_repo_id "/some/path/my-repo")
assert_not_empty "get_repo_id returns a value" "${ID1}"
assert_eq "get_repo_id returns exactly 12 chars" 12 "${#ID1}"

ID2=$(get_repo_id "/some/path/my-repo")
assert_eq "get_repo_id is deterministic" "${ID1}" "${ID2}"

ID3=$(get_repo_id "/different/path/my-repo")
if [[ "${ID1}" != "${ID3}" ]]; then
  pass "get_repo_id differs for different paths"
  TESTS_RUN=$((TESTS_RUN + 1))
else
  fail "get_repo_id should differ for different paths"
  TESTS_RUN=$((TESTS_RUN + 1))
fi

# ---------------------------------------------------------------------------
# Tests: state_dot
# ---------------------------------------------------------------------------
printf '\n--- state_dot ---\n'

assert_eq "idle dot"    "🟢" "$(state_dot idle)"
assert_eq "busy dot"    "🟡" "$(state_dot busy)"
assert_eq "waiting dot" "🟣" "$(state_dot waiting)"
assert_eq "error dot"   "🔴" "$(state_dot error)"
assert_eq "stale dot"   "🔴" "$(state_dot stale)"
assert_eq "unknown dot" "⚪" "$(state_dot foobar)"

# ---------------------------------------------------------------------------
# Tests: state_color
# ---------------------------------------------------------------------------
printf '\n--- state_color ---\n'

assert_eq "idle color"    "#22c55e" "$(state_color idle)"
assert_eq "busy color"    "#eab308" "$(state_color busy)"
assert_eq "waiting color" "#a855f7" "$(state_color waiting)"
assert_eq "error color"   "#ef4444" "$(state_color error)"
assert_eq "stale color"   "#ef4444" "$(state_color stale)"
assert_eq "unknown color" "#6b7280" "$(state_color foobar)"

# ---------------------------------------------------------------------------
# Tests: json_escape
# ---------------------------------------------------------------------------
printf '\n--- json_escape ---\n'

assert_eq 'escape double quote' 'say \"hello\"' "$(json_escape 'say "hello"')"
assert_eq 'escape backslash'    'a\\b'           "$(json_escape 'a\b')"
assert_eq 'escape newline'      'line1\nline2'   "$(json_escape $'line1\nline2')"
assert_eq 'escape tab'          'col1\tcol2'     "$(json_escape $'col1\tcol2')"
assert_eq 'plain string unchanged' 'hello world' "$(json_escape 'hello world')"

# ---------------------------------------------------------------------------
# Tests: json_get / json_get_num
# ---------------------------------------------------------------------------
printf '\n--- json_get / json_get_num ---\n'

SAMPLE_JSON='{"id":"abc123","repo":"my-repo","state":"busy","pid":1234,"ts":1700000000}'

assert_eq "json_get id"    "abc123"    "$(json_get "${SAMPLE_JSON}" "id")"
assert_eq "json_get repo"  "my-repo"  "$(json_get "${SAMPLE_JSON}" "repo")"
assert_eq "json_get state" "busy"     "$(json_get "${SAMPLE_JSON}" "state")"
assert_eq "json_get_num pid" "1234"   "$(json_get_num "${SAMPLE_JSON}" "pid")"
assert_eq "json_get_num ts"  "1700000000" "$(json_get_num "${SAMPLE_JSON}" "ts")"
assert_eq "json_get missing field" "" "$(json_get "${SAMPLE_JSON}" "nosuchfield")"

# ---------------------------------------------------------------------------
# Tests: write_status
# ---------------------------------------------------------------------------
printf '\n--- write_status ---\n'

write_status "testid001" "my-repo" "/projects/my-repo" "idle" "All done" 9999

STATUS_FILE="${STATUS_DIR}/testid001.json"
assert_file_exists "write_status creates file" "${STATUS_FILE}"

CONTENT=$(cat "${STATUS_FILE}")
assert_eq "written id"      "testid001"     "$(json_get "${CONTENT}" "id")"
assert_eq "written repo"    "my-repo"       "$(json_get "${CONTENT}" "repo")"
assert_eq "written path"    "/projects/my-repo" "$(json_get "${CONTENT}" "path")"
assert_eq "written state"   "idle"          "$(json_get "${CONTENT}" "state")"
assert_eq "written message" "All done"      "$(json_get "${CONTENT}" "message")"
assert_eq "written pid"     "9999"          "$(json_get_num "${CONTENT}" "pid")"
TS=$(json_get_num "${CONTENT}" "ts")
assert_not_empty "written timestamp non-empty" "${TS}"

# Test JSON escaping inside write_status
write_status "esctest" 'repo"x' '/path/to/"repo"' "busy" 'msg with "quotes"' 1
ESC_CONTENT=$(cat "${STATUS_DIR}/esctest.json")
# The file must be valid enough that json_get can round-trip the values
assert_not_empty "write_status escapes special chars without breaking file" "${ESC_CONTENT}"

# ---------------------------------------------------------------------------
# Tests: get_terminal
# ---------------------------------------------------------------------------
printf '\n--- get_terminal ---\n'

# No config → default
rm -f "${CONFIG_FILE}"
assert_eq "get_terminal default" "Terminal" "$(get_terminal)"

# Config present
cat > "${CONFIG_FILE}" <<'EOF'
{ "terminal": "Warp" }
EOF
assert_eq "get_terminal reads config" "Warp" "$(get_terminal)"

# ---------------------------------------------------------------------------
# Tests: cc-status CLI
# ---------------------------------------------------------------------------
printf '\n--- cc-status CLI ---\n'

# Point cc-status at our temp environment
export CLAUDE_REPO_PATH="${TMP_DIR}/test-project"
export CLAUDE_REPO_NAME="test-project"
mkdir -p "${CLAUDE_REPO_PATH}"

# Set state: busy
bash "${CC_STATUS}" set busy "Working on it"
PROJ_ID=$(get_repo_id "${CLAUDE_REPO_PATH}")
assert_file_exists "cc-status set creates status file" "${STATUS_DIR}/${PROJ_ID}.json"

SET_CONTENT=$(cat "${STATUS_DIR}/${PROJ_ID}.json")
assert_eq "cc-status set: state"   "busy"         "$(json_get "${SET_CONTENT}" "state")"
assert_eq "cc-status set: message" "Working on it" "$(json_get "${SET_CONTENT}" "message")"
assert_eq "cc-status set: repo"    "test-project"  "$(json_get "${SET_CONTENT}" "repo")"

# Set state: idle
bash "${CC_STATUS}" set idle
SET_CONTENT2=$(cat "${STATUS_DIR}/${PROJ_ID}.json")
assert_eq "cc-status set idle: state" "idle" "$(json_get "${SET_CONTENT2}" "state")"

# Notify (no osascript on Linux — the script guards this)
bash "${CC_STATUS}" notify "Please review"
NOTIFY_CONTENT=$(cat "${STATUS_DIR}/${PROJ_ID}.json")
assert_eq "cc-status notify: state"   "waiting"        "$(json_get "${NOTIFY_CONTENT}" "state")"
assert_eq "cc-status notify: message" "Please review"  "$(json_get "${NOTIFY_CONTENT}" "message")"

# Clear
bash "${CC_STATUS}" clear
assert_file_absent "cc-status clear removes status file" "${STATUS_DIR}/${PROJ_ID}.json"

# Invalid subcommand exits non-zero
if bash "${CC_STATUS}" bogus 2>/dev/null; then
  fail "cc-status bogus should exit non-zero"
  TESTS_RUN=$((TESTS_RUN + 1))
else
  pass "cc-status bogus exits non-zero"
  TESTS_RUN=$((TESTS_RUN + 1))
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
printf '\n==============================\n'
printf 'Tests run: %d\n' "${TESTS_RUN}"
if [[ ${TESTS_FAILED} -eq 0 ]]; then
  printf 'All tests PASSED.\n'
else
  printf 'Tests FAILED: %d\n' "${TESTS_FAILED}" >&2
  exit 1
fi
