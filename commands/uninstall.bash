#!/usr/bin/env bash

help() {
  printf "Uninstall Python version.\n\n"
  printf "Usage: pymac uninstall <Major.Minor version number>\n"
}

uninstall() {
  # Delete directory in /Library/Frameworks/Python.framework/Version
  local py_version="$1"
  local py_dir=/Library/Frameworks/Python.framework/Versions/"$py_version"

  sudo rm -rf "$py_dir" || printf "Failed to delete Python version %s.\n" "$py_version" && return 1
}

parse_args() {
  while :; do
    case "$1" in
      [0-9][.][0-9]*)
        uninstall "$1"
        break
        ;;
      -h|help|--help|"")
        help
        break
        ;;
      *)
        printf "Invalid command. Check 'pymac uninstall help' for usage.\n"
        break
    esac
  done
}

parse_args "$@"
