#!/usr/bin/env bash

help() {
  printf "Directly call specified Python version. This allows you to run a\n"
  printf "script with a specific version (e.g. 'pymac exec 3.9 <file>'), create\n"
  printf "a virtualenv with a specific version ('pymac exec 3.10 -m venv <name>')\n"
  printf "and more. Just calling 'pymac exec <version>' without additional args\n"
  printf "will start Python REPL with the specified version.\n\n"
  printf "Usage: pymac exec <Minor.Major version> <args to Python or file>\n"
}

exec_py() {
  local py_version="$1"
  shift
  local py_exec=/Library/Frameworks/Python.framework/Versions/"$py_version"/bin/python"$py_version"
  "$py_exec" "$@"
}

parse_args() {
  while :; do
    case "$1" in
      [0-9][.][0-9]*)
        exec_py "$@"
        break
        ;;
      -h|help|--help|"")
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
