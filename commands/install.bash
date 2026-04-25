#!/usr/bin/env bash

help() {
  printf "Download, install and set up Python version. If only Major.Minor version\n"
  printf "number provided (e.g. 3.10), the latest available Micro version number is picked\n"
  printf "(e.g. 3.10.4).\n\n"
  printf "Note that pymac only installs Python itself and Pip. The following additional\n"
  printf "features of the Python.org installer are excluded: GUI Applications, UNIX command\n"
  printf "line toos, Python Documentation, Shell profile updater.\n\n"
  printf "Usage: pymac install <Major.Minor.Micro OR Major.Minor version number> [-d/--default] [-i/--interactive] [-k/keep]\n\n"
  printf "Optional arguments:\n"
  printf "  -d/--default:     Symlink Python version to ~/.config/pymac/default after install\n"
  printf "  -i/--interactive: Open the PKG in macOS Installer instead of installing via command line\n"
  printf "  -k/--keep:        Do not delete PKG file after install completed, keep it in \$PYMAC_ROOT/cache\n"
}

download_installer() {
  local py_version_long="$1"
  local pkg="$2"
  local cache_dir
  cache_dir="$(pymac_dir)/cache"
  # Make sure cache dir exists
  mkdir -p "$cache_dir"
  local url
  # If a Python dev version was provided (e.g. 3.11.0a6), extract
  # the version number without the appended 'aX', 'bX' or 'rcX'
  # to correctly build URL
  if [[ "$py_version_long" =~ ^([0-9][.][0-9]{1,2}[.]0)([a-z]{1,2}[0-9]{1,2})$ ]]; then
    url=https://www.python.org/ftp/python/${BASH_REMATCH[1]}/"$pkg"
  else
    url=https://www.python.org/ftp/python/"$py_version_long"/"$pkg"
  fi

  # Only attempt to download if the file doesn't exist
  if [[ ! -e $cache_dir/$pkg ]]; then
    # Check if URL is available
    status_code=$(curl -o /dev/null --silent -Iw '%{http_code}' "$url")
    if [[ $status_code == "200" ]]; then
      curl -O -L --output-dir "$cache_dir" "$url"
    else
      printf "The following URL is not available:\n"
      printf "%s\n\n" "$url"
      printf "Possible reasons:\n"
      printf "  - The provided Python version doesn't exist\n"
      printf "  - There is no macOS installer for the provided Python version\n"
      printf "  - pymac hasn't been updated to reflect changes in Python.org's structure and/or naming schemes\n\n"
      printf "Please report a bug if you see this message but are sure that the Python version exists\n"
      printf "and has a macOS installer.\n"
      exit 1
    fi
  fi
}

generate_choices_xml() {
  # This generates a ChoiceChangesXML file for Python PKG installers.
  # ChoiceChangesXML files can be used to customize PKG installations
  # via the command line. The XML files we generate only install Python
  # itself and Pip.
  #
  # A generator function for choice XML files is needed because Python
  # installers include version numbers in the names of the different
  # choices. For example, the Python Desktop applications are named
  # 'org.python.Python.PythonApplications-3.8' this for Python 3.8
  # and 'org.python.Python.PythonApplications-3.10' for Python 3.10.
  # To solve this, we use a template XML file with placeholders for the
  # version numbers. We use bash pattern replacement to generate files
  # with the correct numbers.
  local py_version="$1"
  local choices
  # Load the template file
  choices=$(cat "$(pymac_dir)"/choices_xml/choices_template.xml)
  # Use pattern replacement to insert Python version numbers
  choices=${choices//##-PyVersion-##/$py_version}
  # Save new XML choice file
  printf "%s" "$choices" >"$(pymac_dir)"/choices_xml/choices_"$py_version".xml
}

verify_pkg_signature() {
  # Verify the downloaded PKG was signed by an expected Python.org signer
  # and run Apple's notarization/Gatekeeper assessment before handing it
  # to sudo installer.
  #
  # Python 3.11+ PKGs are signed by the Python Software Foundation; earlier
  # PKGs are signed by core developer Ned Deily.
  local pkg="$1"
  local py_version_short="$2"
  local pkg_path="$(pymac_dir)/cache/$pkg"
  local sig_output
  if ! sig_output=$(pkgutil --check-signature "$pkg_path" 2>&1); then
    printf "Signature verification failed for %s.\n" "$pkg" >&2
    printf "The PKG is unsigned or its signature is invalid. Refusing to install.\n" >&2
    return 1
  fi

  # Run Apple's notarization / Gatekeeper assessment.
  # Catches PKGs that were never notarized or whose signing cert was revoked.
  if ! spctl --assess --type install "$pkg_path" >/dev/null 2>&1; then
    printf "Notarization check failed for %s.\n" "$pkg" >&2
    printf "Apple Gatekeeper rejected this installer (not notarized or revoked).\n" >&2
    return 1
  fi

  local minor=${py_version_short#*.}
  local expected_signer
  if [[ $minor -ge 11 ]]; then
    expected_signer="Python Software Foundation"
  else
    expected_signer="Ned Deily"
  fi

  if ! grep -q "$expected_signer" <<<"$sig_output"; then
    printf "Signature verification failed for %s.\n" "$pkg" >&2
    printf "Expected signer '%s' not found in the certificate chain.\n" "$expected_signer" >&2
    return 1
  fi
}

call_installer() {
  local py_version_short="$1"
  local pkg="$2"
  local choice_xml
  choice_xml="$(pymac_dir)"/choices_xml/choices_"$py_version_short".xml

  # Generate choice XML file if necessary
  if [[ ! -e $choice_xml ]]; then
    generate_choices_xml "$py_version_short" || exit 1
  fi

  sudo installer -applyChoiceChangesXML "$choice_xml" -pkg "$(pymac_dir)"/cache/"$pkg" -target / || exit 1
}

symlink_executables() {
  # The Python.org installer only provides 'python3', 'pip3' etc. by
  # default. We also want 'python', 'pip' etc. to point at Python 3, so we
  # create symlinks with those names in Python's 'bin' directory
  local py_version_short="$1"
  local py_bin_dir=/Library/Frameworks/Python.framework/Versions/"$py_version_short"/bin
  local default_names=("python" "pip" "idle" "pydoc" "python-config")

  for executable in "${default_names[@]}"; do
    local symlink_target="$py_bin_dir/$executable"
    if [[ ! -e $symlink_target ]]; then
      if [[ $executable != "python-config" ]]; then
        local symlink_source="$executable$py_version_short"
      else
        local symlink_source="python$py_version_short-config"
      fi
      ln -s "$symlink_source" "$symlink_target"
    fi
  done

  # Next, make sure ~/.local/bin exists and create a pythonX.X(X) symlink in it
  # to make calling or specifying installed Python version easier
  mkdir -p ~/.local/bin
  ln -s -f "$py_bin_dir"/python"$py_version_short" ~/.local/bin/python"$py_version_short"
}

resolve_version() {
  # Resolve a user-provided version string into py_version_short,
  # py_version_long, and pkg. These are set as globals for the caller.
  local py_version="$1"

  # Split $py_version into an array structured as follows (using version 3.10.3 as an example):
  # ${PYVERSION[0]} = MAJOR (3)
  # ${PYVERSION[1]} = MINOR (10)
  # ${PYVERSION[2]} = MICRO (3)
  IFS='.' read -ra PYVERSION <<<"$py_version"
  if [[ ${PYVERSION[0]} -lt 3 || "${PYVERSION[1]}" -lt 6 ]]; then
    printf "Minimum supported version is Python 3.6.\n"
    exit 1
  fi

  # If MAJOR.MINOR.MICRO provided (e.g. 3.10.2), use it directly
  if [[ ${#PYVERSION[@]} -eq 3 ]]; then
    py_version_long="$py_version"
    py_version_short="${PYVERSION[0]}.${PYVERSION[1]}"
  else
    # If MAJOR.MINOR provided, query python.org for the latest version
    # that has a macOS PKG installer
    py_version_short="$py_version"
    if ! get_latest_pkg_version "$py_version_short"; then
      return 1
    fi
    py_version_long=${LATEST_PKG_INFO[0]}
    local outdated=${LATEST_PKG_INFO[1]}
    if [[ -n $outdated ]]; then
      printf "You're about to install an outdated version of Python %s (%s)\n" "$py_version_short" "$py_version_long"
      printf "The latest security updates for %s are only available as source code.\n" "$py_version_short"
      printf "You can install them with other tools like uv, pyenv, or asdf-python.\n"
      read -r -p "Continue anyway? [y/n] " input
      if ! [[ $input =~ ^(yes|y|Y|Yes|YES)$ ]]; then
        return 1
      fi
    fi
  fi

  # Use minor Python version to determine file name of pkg installer
  # Needed because Python.org introduced a new 'universal' installer
  # for macOS in Python 3.8.
  if [[ ${PYVERSION[1]} -gt 8 ]]; then
    pkg=python-"$py_version_long"-macos11.pkg
  else
    pkg=python-"$py_version_long"-macosx10.9.pkg
  fi
}

interactive_install() {
  download_installer "$py_version_long" "$pkg" || return 1
  verify_pkg_signature "$pkg" "$py_version_short" || return 1
  open "$(pymac_dir)/cache/$pkg"
  printf "Opened %s.\n" "$pkg"
  printf "The PKG file is kept in %s/cache. Run 'pymac clear-cache' to remove it.\n" "$(pymac_dir)"
}

cli_install() {
  local keep="$1"

  download_installer "$py_version_long" "$pkg" &&
    verify_pkg_signature "$pkg" "$py_version_short" &&
    call_installer "$py_version_short" "$pkg" &&
    symlink_executables "$py_version_short" &&
    . "$(pymac_dir)"/commands/certifi-update.bash "$py_version_short"
  if ! [[ $keep == true ]]; then
    rm "$(pymac_dir)"/cache/"$pkg"
  fi
}

install() {
  local py_version="$1"
  local keep="$2"
  local interactive="$3"

  resolve_version "$py_version" || return 1

  # Check if the exact version to be installed is already present by
  # querying the installed Python binary's --version output. This avoids
  # an unnecessary download and sudo prompt when the user is already
  # up-to-date. Only an exact match triggers the prompt — e.g. if 3.14.1
  # is installed and 3.14.2 is requested, installation proceeds normally.
  local py_bin_to_check=/Library/Frameworks/Python.framework/Versions/"$py_version_short"/bin/python"$py_version_short"
  if [[ -x $py_bin_to_check && $("$py_bin_to_check" --version 2>&1 | sed 's/Python //') == "$py_version_long" ]]; then
    printf "Python %s is already installed.\n" "$py_version_long"
    read -r -p "Reinstall? [y/n] " input
    if ! [[ $input =~ ^(yes|y|Y|Yes|YES)$ ]]; then
      return 0
    fi
  fi

  if [[ $interactive == true ]]; then
    interactive_install
  else
    cli_install "$keep"
  fi
}

parse_args() {
  local py_version
  local default=false
  local interactive=false
  local keep=false
  # Save count of args before potentially using shift
  # Used to determine if help should be printed when
  # no args provided
  local arg_count="$#"
  while :; do
    case "$1" in
    [0-9].[0-9]*)
      if py_valid "$1"; then
        py_version="$1"
        shift
      else
        printf "Please provide a valid Python version number.\n"
        return 1
      fi
      ;;
    -h | help | --help)
      help
      break
      ;;
    -d | --default)
      default=true
      shift
      ;;
    -i | --interactive)
      interactive=true
      shift
      ;;
    -k | --keep)
      keep=true
      shift
      ;;
    "")
      # If any args have been provided, do nothing, else print help
      if [[ $arg_count -gt 0 ]]; then
        break
      else
        help
        break
      fi
      ;;
    *)
      printf "Invalid command. Check 'pymac install help' for usage.\n"
      return 1
      ;;
    esac
  done

  if [[ -z "$py_version" && ($default == true || $interactive == true || $keep == true) ]]; then
    printf "Please provide a valid Python version number.\n"
    return 1
  fi

  if [[ -n "$py_version" ]]; then
    install "$py_version" "$keep" "$interactive"
    if [[ $default == true ]]; then
      . "$(pymac_dir)"/commands/default.bash "$py_version"
    fi
  fi
}

parse_args "$@"
