# Shared helpers for the Spotify Local developer CLI.
# shellcheck shell=bash

spotify_local_init() {
  : "${SPOTIFY_LOCAL_ROOT:?SPOTIFY_LOCAL_ROOT is required}"
  SPOTIFY_LOCAL_RUN_DIR="${SPOTIFY_LOCAL_RUN_DIR:-$SPOTIFY_LOCAL_ROOT/.run}"
  SPOTIFY_LOCAL_LOG_DIR="${SPOTIFY_LOCAL_LOG_DIR:-$SPOTIFY_LOCAL_RUN_DIR/logs}"
  SPOTIFY_LOCAL_MUSIC_DIR="${SPOTIFY_LOCAL_MUSIC_DIR:-$HOME/Desktop/Spotify Local}"
  SPOTIFY_LOCAL_BUNDLE_ID="${SPOTIFY_LOCAL_BUNDLE_ID:-app.spotifylocal.ios}"
  SPOTIFY_LOCAL_APP_NAME="SpotifyLocal"
  SPOTIFY_LOCAL_IOS_PROJECT="$SPOTIFY_LOCAL_ROOT/ios/SpotifyLocal/SpotifyLocal.xcodeproj"
  SPOTIFY_LOCAL_COMPANION_PACKAGE="$SPOTIFY_LOCAL_ROOT/mac/SpotifyLocalCompanion"
  SPOTIFY_LOCAL_MAC_APP_PACKAGE="$SPOTIFY_LOCAL_ROOT/mac/SpotifyLocalApp"
  SPOTIFY_LOCAL_MAC_APP_BUNDLE="$SPOTIFY_LOCAL_RUN_DIR/SpotifyLocal.app"
  SPOTIFY_LOCAL_VERBOSE="${SPOTIFY_LOCAL_VERBOSE:-0}"
  mkdir -p "$SPOTIFY_LOCAL_RUN_DIR" "$SPOTIFY_LOCAL_LOG_DIR"
  export SPOTIFY_LOCAL_ROOT SPOTIFY_LOCAL_RUN_DIR SPOTIFY_LOCAL_LOG_DIR
  export SPOTIFY_LOCAL_MUSIC_DIR SPOTIFY_LOCAL_BUNDLE_ID SPOTIFY_LOCAL_VERBOSE
}

spotify_local_is_tty() {
  [[ -t 1 ]]
}

spotify_local_color() {
  local code="$1"
  shift
  if spotify_local_is_tty && [[ -z "${NO_COLOR:-}" ]]; then
    printf '\033[%sm%s\033[0m' "$code" "$*"
  else
    printf '%s' "$*"
  fi
}

spotify_local_ok() { spotify_local_color '32' "✓"; }
spotify_local_fail() { spotify_local_color '31' "✗"; }
spotify_local_warn() { spotify_local_color '33' "!"; }

spotify_local_log() {
  local message="$*"
  printf '%s\n' "$message" >>"$SPOTIFY_LOCAL_LOG_DIR/dev.log"
  if [[ "$SPOTIFY_LOCAL_VERBOSE" == "1" ]]; then
    printf '%s\n' "$message" >&2
  fi
}

spotify_local_die() {
  printf '%s %s\n' "$(spotify_local_fail)" "$*" >&2
  exit 1
}

spotify_local_pid_alive() {
  local pid="${1:-}"
  [[ -n "$pid" ]] || return 1
  kill -0 "$pid" 2>/dev/null
}

spotify_local_read_pid() {
  local file="$1"
  [[ -f "$file" ]] || return 1
  local pid
  pid="$(tr -d '[:space:]' <"$file")"
  [[ "$pid" =~ ^[0-9]+$ ]] || return 1
  printf '%s\n' "$pid"
}

spotify_local_companion_pid_file() {
  printf '%s\n' "$SPOTIFY_LOCAL_RUN_DIR/companion.pid"
}

spotify_local_companion_running() {
  local pid
  pid="$(spotify_local_read_pid "$(spotify_local_companion_pid_file)" || true)"
  spotify_local_pid_alive "${pid:-}"
}

spotify_local_xcode_developer_dir() {
  if [[ -d /Applications/Xcode.app/Contents/Developer ]]; then
    printf '%s\n' /Applications/Xcode.app/Contents/Developer
    return 0
  fi
  local current
  current="$(xcode-select -p 2>/dev/null || true)"
  if [[ -n "$current" && "$current" != "/Library/Developer/CommandLineTools" ]]; then
    printf '%s\n' "$current"
    return 0
  fi
  return 1
}

spotify_local_prepare_xcode() {
  local developer_dir
  if developer_dir="$(spotify_local_xcode_developer_dir)"; then
    export DEVELOPER_DIR="$developer_dir"
    return 0
  fi
  return 1
}

spotify_local_has_simctl() {
  spotify_local_prepare_xcode || return 1
  xcrun --find simctl >/dev/null 2>&1
}

spotify_local_expand_home() {
  local path="$1"
  if [[ "$path" == "$HOME"* ]]; then
    printf '~%s\n' "${path#"$HOME"}"
  else
    printf '%s\n' "$path"
  fi
}

spotify_local_mac_app_binary() {
  printf '%s\n' "$SPOTIFY_LOCAL_MAC_APP_BUNDLE/Contents/MacOS/SpotifyLocalApp"
}

spotify_local_mac_app_running() {
  local bin
  bin="$(spotify_local_mac_app_binary)"
  [[ -x "$bin" ]] || return 1
  pgrep -f "$bin" >/dev/null 2>&1
}

spotify_local_stop_mac_app() {
  local bin pid
  bin="$(spotify_local_mac_app_binary)"
  [[ -e "$bin" ]] || return 0
  while pid="$(pgrep -f "$bin" | head -n 1)"; do
    [[ -n "$pid" ]] || break
    kill "$pid" 2>/dev/null || true
    sleep 0.1
    if spotify_local_pid_alive "$pid"; then
      kill -TERM "$pid" 2>/dev/null || true
    fi
    sleep 0.1
    spotify_local_pid_alive "$pid" || break
    break
  done
}
