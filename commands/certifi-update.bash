#!/usr/bin/env bash

help() {
  printf "Install and set up SSL root certificates from certifi package.\n"
  printf "Replicates the 'Install Certificates.command' that comes with the\n"
  printf "GUI applications from the Python.org installer. Required because\n"
  printf "Python.org installers include their own private copy of OpenSSL.\n\n"
  printf "Note: This is executed automatically when you install a Python version\n"
  printf "with pymac. You only need to run it separately if it failed during the\n"
  printf "installation or if you want to update the certifi package.\n\n"
  printf "Usage: pymac certifi-update <Major.Minor version number>\n"
  printf "       pymac certifi-update --all\n\n"
  printf "Optional arguments:\n"
  printf "  -a/--all: Update certifi for all installed Python versions\n"
}

update_certifi() {
  local py_version="$1"
  local py_dir=/Library/Frameworks/Python.framework/Versions/"$py_version"
  local cert_file="$py_dir"/etc/openssl/cert.pem

  # Install https://pypi.org/project/certifi/ into local site-packages
  # Prefer uv if available, fall back to pip
  if command -v uv &>/dev/null; then
    local install_cmd=(uv pip install --python "$py_dir"/bin/python3 --upgrade certifi)
  else
    # Set PIP_REQUIRE_VIRTUALENV to false to make sure this works if pip
    # is configured to only allow installing packages in virtualenvs
    local install_cmd=(env PIP_REQUIRE_VIRTUALENV=false
      "$py_dir"/bin/python3 -E -m pip install --upgrade pip certifi)
  fi
  if "${install_cmd[@]}"; then
    # Remove old cert file if it exists
    rm -f "$cert_file"
    # Symlink certifi's cacert.pem to $cert_file
    ln -s ../../lib/python"$py_version"/site-packages/certifi/cacert.pem "$cert_file"
    # Adjust file permissions
    chmod 755 "$cert_file"
  else
    printf "Failed to install certifi.\n"
    return 1
  fi
}

update_all_certifi() {
  local versions_dir=/Library/Frameworks/Python.framework/Versions
  local found=false
  for entry in "$versions_dir"/[0-9].[0-9]*; do
    local version="${entry##*/}"
    found=true
    printf "Updating certifi for Python %s...\n" "$version"
    update_certifi "$version"
  done
  if [[ $found == false ]]; then
    printf "No installed Python versions found.\n"
  fi
}

parse_args() {
  while :; do
    case "$1" in
    [0-9][.][0-9]*)
      update_certifi "$1"
      break
      ;;
    -a | --all)
      update_all_certifi
      break
      ;;
    -h | help | --help | "")
      help
      break
      ;;
    *)
      printf "Invalid command. Check 'pymac certifi-update help' for usage.\n"
      break
      ;;
    esac
  done
}

parse_args "$@"
