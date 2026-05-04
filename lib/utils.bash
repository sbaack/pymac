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
  # MAJOR.MINOR.MICROdev-version (e.g. 3.11.0a6, 3.14.5rc1)
  local py_version="$1"
  [[ $py_version =~ ^3[.][0-9]{1,2}([.][0-9]{1,2}([a-z]{1,2}[0-9]{1,2})?)?$ ]]
}

is_installed() {
  local py_version="$1"
  local py_dir=/Library/Frameworks/Python.framework/Versions/"$py_version"
  [[ -d $py_dir ]]
}

get_latest_pkg_version() {
  # Look up the latest macOS PKG version for a given Major.Minor and parse
  # the result into the LATEST_PKG_INFO global array:
  #   LATEST_PKG_INFO[0] = version string (e.g. "3.13.13")
  #   LATEST_PKG_INFO[1] = "outdated" if newer source-only releases exist
  #
  # Returns 0 on success, 1 on failure.
  local py_version_short="$1"
  LATEST_PKG_INFO=()
  IFS=$'\n' read -d '' -r -a LATEST_PKG_INFO <<<"$(_scrape_pkg_versions "$py_version_short")"
  [[ -n ${LATEST_PKG_INFO[0]} ]]
}

_scrape_pkg_versions() {
  # Query python.org to find the latest version of a given Major.Minor
  # that has a macOS PKG installer available.
  #
  # Output (stdout):
  #   Line 1: version string (e.g. "3.13.13" or "3.15.0a8")
  #   Line 2: "outdated" if newer source-only releases exist
  #
  # Returns 0 on success, 1 if no PKG is found or network is unreachable.
  local py_version_short="$1"
  local base_url="https://www.python.org/ftp/python/"

  # Fetch the FTP index and extract version directories matching the
  # requested Major.Minor, then sort by micro version descending. Capture
  # curl's output separately so its exit code is observable — without this,
  # we can't distinguish a network failure from a missing version.
  local index_html
  if ! index_html=$(curl -sf --max-time 10 "$base_url"); then
    printf "Could not reach python.org. Check your internet connection.\n" >&2
    return 1
  fi
  local versions
  versions=$(
    printf "%s" "$index_html" |
      sed -n "s/.*href=\"\(${py_version_short}\.[0-9][0-9]*\)\/.*/\1/p" |
      sort -t. -k3 -n -r
  )

  if [[ -z $versions ]]; then
    printf "Could not find Python %s on python.org.\n" "$py_version_short" >&2
    return 1
  fi

  # Starting from the highest micro version, check if a macOS PKG exists.
  # If we have to skip versions before finding a PKG, the series has
  # moved to source-only releases (i.e. the macOS installer version is "outdated").
  local version
  local skipped=false
  for version in $versions; do
    local pkg_html
    if ! pkg_html=$(curl -sf --max-time 10 "${base_url}${version}/"); then
      printf "Could not reach python.org. Check your internet connection.\n" >&2
      return 1
    fi
    local pkg_name
    pkg_name=$(
      printf "%s" "$pkg_html" |
        sed -n 's/.*href="\(python-[^"]*-macos[^"]*\.pkg\)".*/\1/p' |
        sort -r |
        head -1
    )
    if [[ -n $pkg_name ]]; then
      # Extract the version string from the PKG filename, which may
      # include pre-release suffixes (e.g. "3.15.0a8" from
      # "python-3.15.0a8-macos11.pkg")
      sed 's/python-\(.*\)-macos.*/\1/' <<<"$pkg_name"
      if [[ $skipped == true ]]; then
        printf "outdated\n"
      fi
      return 0
    fi
    skipped=true
  done

  printf "No macOS installer found for any Python %s release.\n" "$py_version_short" >&2
  return 1
}
