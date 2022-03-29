#!/usr/bin/env bash

help() {
  printf "Show path to Python version symlinked to ~/.config/pymac/default.\n\n"
  printf "Usage: pymac default-which <Major.Minor version number>\n"
}

default-which() {
  local default
  default=$(readlink ~/.config/pymac/default)
  if [[ -z "$default" ]]; then
    printf "No default set.\n"
  else
    printf "%s/bin/python3\n" "$default"
  fi
}

parse_args() {
  while :; do
    case "$1" in
      "")
        default-which
        break
        ;;
      -h|help|--help)
        help
        break
        ;;
      *)
        printf "Invalid option. See 'pymac default help' for usage.\n"
        exit 1
    esac
  done
}

parse_args "$@"
