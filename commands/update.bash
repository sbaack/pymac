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
  IFS=$'\n' read -d '' -r -a latest < "$(pymac_dir)/latest_versions/$py_version"
  local latest_available=${latest[0]}

  if [[ $installed_py_version == "$latest_available" ]]; then
    printf "Version %s is already at the latest known version (%s).\n" "$py_version" "$installed_py_version"
  else
    printf "Updating %s to %s...\n" "$installed_py_version" "$latest_available"
    . "$(pymac_dir)"/commands/install.bash "$py_version"
  fi
}

parse_args() {
  while :; do
    case "$1" in
      [0-9][.][0-9]*)
        update "$1"
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
