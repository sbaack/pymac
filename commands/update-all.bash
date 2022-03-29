#!/usr/bin/env bash

help() {
  printf "Update all Python version installed via pymac to the latest known Micro versions.\n\n"
  printf "Usage: pymac update-all\n"
}

update-all() {
  local install_dir=/Library/Frameworks/Python.framework/Versions
  local py_version

  for dir in "$install_dir"/*; do
    py_version=$(basename "$dir")
    if py_valid "$py_version"; then
      # shellcheck disable=1090
      . "$(pymac_dir)"/commands/update.bash "$py_version"
    fi
  done
}

parse_args() {
  while :; do
    case "$1" in
      "")
        update-all
        break
        ;;
      -h|help|--help)
        help
        break
        ;;
      *)
        printf "Invalid command. Check 'pymac update help' for usage.\n"
        break
    esac
  done
}

parse_args "$@"
