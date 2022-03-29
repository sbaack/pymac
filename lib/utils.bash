#!/usr/bin/env bash

pymac_dir() {
  if [ -z "$PYMAC_DIR" ]; then
    local current_script_path=${BASH_SOURCE[0]}
    export PYMAC_DIR
    PYMAC_DIR=$(
      cd "$(dirname "$(dirname "$current_script_path")")" || exit
      pwd
    )
  fi

  printf "%s\n" "$PYMAC_DIR"
}

py_valid() {
  # Validate Python version provided. Accepted formats:
  # MAJOR.MINOR                  (e.g. 3.10)
  # MAJOR.MINOR.MICRO            (e.g. 3.10.3)
  # MAJOR.MINOR.MICROdev-version (e.g. 3.11.0a6)
  local py_version="$1"
  [[ $py_version =~ ^[0-3][.][0-9]{1,2}([.]0[a-z]{1,2}[0-9]{1,2}|[.][0-9]{1,2})?$ ]]
}

is_installed() {
  local py_version="$1"
  local py_dir=/Library/Frameworks/Python.framework/Versions/"$py_version"
  [[ -d $py_dir ]]
}
