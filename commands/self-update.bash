#!/usr/bin/env bash

help() {
  printf "Update pymac itself to the latest HEAD version.\n\n"
  printf "Usage: pymac self-update\n"
}

self_update() {
  (
    cd "$(pymac_dir)" || exit 1
    git fetch origin main
    git checkout main
    git reset --hard origin/main
  )
}

parse_args() {
  while :; do
    case "$1" in
    "")
      self_update
      break
      ;;
    -h | help | --help)
      help
      break
      ;;
    *)
      printf "Invalid command. Check 'pymac self-update help' for usage.\n"
      break
      ;;
    esac
  done
}

parse_args "$@"
