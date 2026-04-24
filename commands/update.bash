#!/usr/bin/env bash

help() {
  printf "Update specified Python version to the latest known Micro version\n\n"
  printf "Usage: pymac update <Major.Minor version number>\n"
}

update() {
  local py_version="$1"
  local py_exec=/Library/Frameworks/Python.framework/Versions/"$py_version"/bin/python3
  local installed_py_version
  installed_py_version=$("$py_exec" --version | cut -d ' ' -f 2)

  if ! get_latest_pkg_version "$py_version"; then
    return 1
  fi
  local latest_available=${LATEST_PKG_INFO[0]}
  local outdated=${LATEST_PKG_INFO[1]}

  if [[ $installed_py_version == "$latest_available" ]]; then
    if [[ -n $outdated ]]; then
      printf "Warning: Latest %s version only available as source code (last version with macOS installer: %s).\n" "$py_version" "$latest_available"
    else
      printf "%s is up-to-date (%s).\n" "$py_version" "$installed_py_version"
    fi
  else
    printf "Updating %s to %s...\n" "$installed_py_version" "$latest_available"
    . "$(pymac_dir)"/commands/install.bash "$latest_available"
  fi
}

parse_args() {
  while :; do
    case "$1" in
    [0-9][.][0-9]*)
      update "$1"
      break
      ;;
    -h | help | --help | "")
      help
      break
      ;;
    *)
      printf "Invalid command. Check 'pymac update help' for usage.\n"
      break
      ;;
    esac
  done
}

parse_args "$@"
