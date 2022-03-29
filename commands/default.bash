#!/usr/bin/env bash

help() {
  printf "Set Python version symlinked to ~/.config/pymac/default.\n\n"
  printf "Usage: pymac default <Major.Minor version number>\n"
}

set-default() {
  local py_version="$1"
  local root_dir=/Library/Frameworks/Python.framework/Versions/"$py_version"
  local symlink_dir=~/.config/pymac

  mkdir -p "$symlink_dir"

  rm -f "$symlink_dir"/default
  ln -s "$root_dir" "$symlink_dir"/default
}

parse_args() {
  while :; do
    case "$1" in
      [0-9][.][0-9]*)
        set-default "$1"
        break
        ;;
      -h|help|--help|"")
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
