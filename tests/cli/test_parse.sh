#!/usr/bin/env bash
# CLI parser and companion lock tests.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=../../scripts/lib/parse.sh
source "$ROOT/scripts/lib/parse.sh"
# shellcheck source=../../scripts/lib/common.sh
source "$ROOT/scripts/lib/common.sh"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

pass=0
assert_eq() {
  local got="$1" want="$2" label="$3"
  if [[ "$got" != "$want" ]]; then
    fail "$label: got '$got' want '$want'"
  fi
  pass=$((pass + 1))
}

spotify_local_parse local || fail "parse local"
assert_eq "$SPOTIFY_LOCAL_COMMAND" "start" "spotify local"

spotify_local_parse local status || fail "parse status"
assert_eq "$SPOTIFY_LOCAL_COMMAND" "status" "spotify local status"

spotify_local_parse local stop || fail "parse stop"
assert_eq "$SPOTIFY_LOCAL_COMMAND" "stop" "spotify local stop"

spotify_local_parse local doctor || fail "parse doctor"
assert_eq "$SPOTIFY_LOCAL_COMMAND" "doctor" "spotify local doctor"

spotify_local_parse local logs || fail "parse logs"
assert_eq "$SPOTIFY_LOCAL_COMMAND" "logs" "spotify local logs"

spotify_local_parse --verbose local || fail "parse verbose"
assert_eq "$SPOTIFY_LOCAL_COMMAND" "start" "verbose start"
assert_eq "$SPOTIFY_LOCAL_VERBOSE" "1" "verbose flag"

if spotify_local_parse noodle; then
  fail "unknown command should fail"
fi

if spotify_local_parse local noodle; then
  fail "unknown subcommand should fail"
fi

if spotify_local_parse local status extra; then
  fail "extra args should fail"
fi

printf 'CLI parser tests passed (%s)\n' "$pass"
