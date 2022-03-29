#!/usr/bin/env bash

help() {
  printf "Upgrade pymac itself to the latest HEAD version.\n\n"
  printf "Usage: pymac upgrade\n"
}

upgrade() {
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
        upgrade
        break
        ;;
      -h|help|--help)
        help
        break
        ;;
      *)
        printf "Invalid command. Check 'pymac upgrade help' for usage.\n"
        break
    esac
  done
}

parse_args "$@"
