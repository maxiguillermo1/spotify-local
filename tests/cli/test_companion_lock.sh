#!/usr/bin/env bash
# Starting the companion twice must reuse a single process.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=../../scripts/lib/common.sh
source "$ROOT/scripts/lib/common.sh"

WORKDIR="$(mktemp -d)"
cleanup() {
  if pid="$(spotify_local_read_pid "$(spotify_local_companion_pid_file)" 2>/dev/null || true)"; then
    if spotify_local_pid_alive "$pid"; then
      kill "$pid" 2>/dev/null || true
      sleep 0.1
    fi
  fi
  rm -rf "$WORKDIR"
}
trap cleanup EXIT

export SPOTIFY_LOCAL_ROOT="$ROOT"
export SPOTIFY_LOCAL_RUN_DIR="$WORKDIR/run"
export SPOTIFY_LOCAL_MUSIC_DIR="$WORKDIR/music"
export SPOTIFY_LOCAL_LOG_DIR="$SPOTIFY_LOCAL_RUN_DIR/logs"
export SPOTIFY_LOCAL_VERBOSE=0
spotify_local_init

swift build --package-path "$ROOT/mac/SpotifyLocalCompanion" -c release --build-path "$SPOTIFY_LOCAL_RUN_DIR/companion-build" >/dev/null
BIN="$SPOTIFY_LOCAL_RUN_DIR/companion-build/release/SpotifyLocalCompanion"

SPOTIFY_LOCAL_RUN_DIR="$SPOTIFY_LOCAL_RUN_DIR" SPOTIFY_LOCAL_MUSIC_DIR="$SPOTIFY_LOCAL_MUSIC_DIR" \
  "$BIN" >/dev/null 2>&1 &
sleep 0.4

spotify_local_companion_running || {
  printf 'FAIL: companion did not start\n' >&2
  exit 1
}

pid1="$(spotify_local_read_pid "$(spotify_local_companion_pid_file)")"

SPOTIFY_LOCAL_RUN_DIR="$SPOTIFY_LOCAL_RUN_DIR" SPOTIFY_LOCAL_MUSIC_DIR="$SPOTIFY_LOCAL_MUSIC_DIR" \
  "$BIN" >/dev/null 2>&1
sleep 0.2

pid2="$(spotify_local_read_pid "$(spotify_local_companion_pid_file)")"
spotify_local_companion_running || {
  printf 'FAIL: companion died after second start\n' >&2
  exit 1
}

if [[ "$pid1" != "$pid2" ]]; then
  printf 'FAIL: duplicate companion pid %s then %s\n' "$pid1" "$pid2" >&2
  exit 1
fi

printf 'Duplicate companion prevention passed (pid %s)\n' "$pid1"
