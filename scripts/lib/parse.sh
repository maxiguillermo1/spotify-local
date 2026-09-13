# Parse `spotify local ...` arguments.
# shellcheck shell=bash

spotify_local_parse() {
  SPOTIFY_LOCAL_COMMAND="start"
  SPOTIFY_LOCAL_VERBOSE="${SPOTIFY_LOCAL_VERBOSE:-0}"
  SPOTIFY_LOCAL_PARSE_ERROR=""

  local args=()
  local arg
  for arg in "$@"; do
    case "$arg" in
      --verbose|-v)
        SPOTIFY_LOCAL_VERBOSE=1
        ;;
      --help|-h)
        args+=("help")
        ;;
      --*)
        SPOTIFY_LOCAL_PARSE_ERROR="Unknown option: $arg"
        return 1
        ;;
      *)
        args+=("$arg")
        ;;
    esac
  done

  set -- "${args[@]+"${args[@]}"}"

  if [[ $# -eq 0 ]]; then
    SPOTIFY_LOCAL_COMMAND="help"
    return 0
  fi

  if [[ "$1" != "local" ]]; then
    SPOTIFY_LOCAL_PARSE_ERROR="Unknown command: $1
Use:  spotify local"
    return 1
  fi
  shift

  if [[ $# -eq 0 ]]; then
    SPOTIFY_LOCAL_COMMAND="start"
    return 0
  fi

  case "$1" in
    start)
      SPOTIFY_LOCAL_COMMAND="start"
      ;;
    stop)
      SPOTIFY_LOCAL_COMMAND="stop"
      ;;
    status)
      SPOTIFY_LOCAL_COMMAND="status"
      ;;
    doctor)
      SPOTIFY_LOCAL_COMMAND="doctor"
      ;;
    logs)
      SPOTIFY_LOCAL_COMMAND="logs"
      ;;
    help)
      SPOTIFY_LOCAL_COMMAND="help"
      ;;
    *)
      SPOTIFY_LOCAL_PARSE_ERROR="Unknown command: spotify local $1
Use:  spotify local
      spotify local status
      spotify local stop
      spotify local doctor
      spotify local logs"
      return 1
      ;;
  esac

  if [[ $# -gt 1 ]]; then
    SPOTIFY_LOCAL_PARSE_ERROR="Unexpected arguments after: spotify local $1"
    return 1
  fi
}
