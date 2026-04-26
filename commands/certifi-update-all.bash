#!/usr/bin/env bash

help() {
  printf "Update certifi package for all Python versions installed via pymac.\n\n"
  printf "Usage: pymac certifi-update-all\n"
}

certifi-update-all() {
  local install_dir=/Library/Frameworks/Python.framework/Versions
  local py_version

  for dir in "$install_dir"/*; do
    py_version=$(basename "$dir")
    if py_valid "$py_version"; then
      printf "Updating certifi for Python %s...\n" "$py_version"
      # shellcheck disable=1090
      . "$(pymac_dir)"/commands/certifi-update.bash "$py_version"
    fi
  done
}

parse_args() {
  while :; do
    case "$1" in
    "")
      certifi-update-all
      break
      ;;
    -h | help | --help)
      help
      break
      ;;
    *)
      printf "Invalid command. Check 'pymac certifi-update-all help' for usage.\n"
      break
      ;;
    esac
  done
}

parse_args "$@"
