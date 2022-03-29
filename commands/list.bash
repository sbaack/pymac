#!/usr/bin/env bash

help() {
  printf "List installed Python versions.\n\n"
  printf "Usage: pymac list [-f/--full]\n\n"
  printf "Optional arguments:\n"
  printf "  -f/--full: Also show full version number (with micro version)\n"
}

list_py_installs() {
  local root_dir=/Library/Frameworks/Python.framework/Versions
  local verbose
  if [[ "$1" == "verbose" ]]; then
    verbose=true
  else
    verbose=false
  fi
  for dir in "$root_dir"/*; do
    directory=$(basename "$dir")
    if py_valid "$directory"; then
      if [[ $verbose == true ]]; then
        printf "%-4s (%s)\n" "$directory" "$("$root_dir/$directory/bin/python3" -V | cut -d ' ' -f 2)"
      else
        printf "%s\n" "$directory"
      fi
    fi
  done
}

parse_args() {
  while :; do
    case "$1" in
      "")
        list_py_installs
        break
        ;;
      -h|help|--help)
        help
        break
        ;;
      -f|--full)
        list_py_installs "verbose"
        break
        ;;
      *)
        printf "Invalid command. Check 'pymac list help' for usage.\n"
        break
    esac
  done
}

parse_args "$@"
