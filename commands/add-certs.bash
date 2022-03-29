#!/usr/bin/env bash

help() {
  printf "Install and set up SSL root certificats from certifi package.\n"
  printf "Replicates the 'Install Certificates.command' that comes with the\n"
  printf "GUI applications from the Python.org installer. Required because\n"
  printf "Python.org installers include their own private copy of OpenSSL.\n\n"
  printf "Note: This is executed automatically when you install a Python version\n"
  printf "with pymac. You only need to run it separately if it failed during the\n"
  printf "installtion or if you want to update the certifi package.\n\n"
  printf "Usage: pymac add-certs <Major.Minor version number>\n"
}

add_certs() {
  local py_version="$1"
  local py_dir=/Library/Frameworks/Python.framework/Versions/"$py_version"
  local cert_file="$py_dir"/etc/openssl/cert.pem

  # Install https://pypi.org/project/certifi/ into local site-packages
  # Set PIP_REQUIRE_VIRTUALENV to false to make sure this works if pip
  # is configured to only allow installing packages in virtualenvs
  if PIP_REQUIRE_VIRTUALENV=false \
    "$py_dir"/bin/python3 -E -m   \
    pip install --upgrade pip setuptools certifi; then
    # Remove old cert file if it exists
    rm -f "$cert_file"
    # Symlink certifi's cacert.pem to $cert_file
    ln -s ../../lib/python"$py_version"/site-packages/certifi/cacert.pem "$cert_file"
    # Adjust file permissions
    chmod 755 "$cert_file"
  else
    printf "Failed to install certifi.\n"
    exit 1
  fi
}

parse_args() {
  while :; do
    case "$1" in
      [0-9][.][0-9]*)
        add_certs "$1"
        break
        ;;
      -h|help|--help|"")
        help
        break
        ;;
      *)
        printf "Invalid command. Check 'pymac add-certs help' for usage.\n"
        break
    esac
  done
}

parse_args "$@"
