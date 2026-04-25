#!/usr/bin/env bash

help() {
  printf "Delete downloaded PKG installers.\n\n"
  printf "Note: PKG installers are deleted by default after install is\n"
  printf "completed successfully. You only need to clear the cache manually\n"
  printf "if an install failed, was interrupted, or if you used the '--keep'\n"
  printf "option of the pymac install command.\n\n"
  printf "Usage: pymac clear-cache\n"
}

clear-cache() {
  rm -f "$(pymac_dir)"/cache/*
}

parse_args() {
  while :; do
    case "$1" in
    "")
      clear-cache
      break
      ;;
    help | --help | -h)
      help
      break
      ;;
    *)
      printf "Invalid command. Check 'pymac clear-cache help' for usage.\n"
      break
      ;;
    esac
  done
}

parse_args "$@"
