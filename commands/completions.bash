#!/usr/bin/env bash

help() {
  printf "Print shell completion script for the specified shell.\n\n"
  printf "Usage: pymac completions <bash|fish|zsh>\n\n"
  printf "Setup:\n"
  printf "  bash: Add to ~/.bashrc:  eval \"\$(pymac completions bash)\"\n"
  printf "  zsh:  Add to ~/.zshrc (after compinit):  eval \"\$(pymac completions zsh)\"\n"
  printf "  fish: Run once:  echo 'pymac completions fish | source' > ~/.config/fish/completions/pymac.fish\n\n"
  printf "Note: The bash completions require bash 4.0+.\n"
}

completions() {
  local shell="$1"
  cat "$(pymac_dir)"/completions/pymac."$shell"
}

parse_args() {
  while :; do
    case "$1" in
    bash | fish | zsh)
      completions "$1"
      break
      ;;
    "" | -h | help | --help)
      help
      break
      ;;
    *)
      printf "Unsupported shell '%s'. Check 'pymac completions help' for usage.\n" "$1"
      return 1
      ;;
    esac
  done
}

parse_args "$@"
