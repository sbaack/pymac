#!/usr/bin/env bash

help() {
  printf "Show path to Python version symlinked to ~/.config/pymac/default.\n\n"
  printf "Usage: pymac default-which [--bare]\n\n"
  printf "Optional arguments:\n"
  printf "  --bare: Only show version number of current default instead of full path\n"
}

default-which() {
  local bare="$1"
  local default
  default=$(readlink ~/.config/pymac/default)
  if [[ -z "$default" ]]; then
    printf "No default set.\n"
  else
    if [[ $bare == true ]]; then
      local version_num
      version_num=$(basename "$default")
      printf "%s\n" "$version_num"
    else
      printf "%s/bin/python3\n" "$default"
    fi
  fi
}

parse_args() {
  local bare=false
  while :; do
    case "$1" in
      "")
        break
        ;;
      --bare)
        bare=true
        break
        ;;
      -h|help|--help)
        help
        return 0
        ;;
      *)
        printf "Invalid option. See 'pymac default help' for usage.\n"
        exit 1
    esac
  done
 default-which "$bare" 
}

parse_args "$@"
