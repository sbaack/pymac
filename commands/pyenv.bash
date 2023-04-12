#!/usr/bin/env bash

help() {
  printf "Manage symlinks of pymac installs in \$PYENV_ROOT/versions.\n\n"
  printf "Creating these symlinks allows you to manage your pymac installs with\n"
  printf "pyenv (e.g. setting them via pyenv global/local/shell). Note that pymac\n"
  printf "names symlinks as Major.Minor (e.g. 3.10) to distinguish them from pyenv\n"
  printf "installs, which are named as Major.Minor.Micro (e.g. 3.10.3).\n\n"
  printf "Usage: pymac pyenv <add>/<remove>/<remove-all>/<sync>\n\n"
  printf "Arguments:\n"
  printf "  add:        Create symlink to specified Python version in \$PYENV_ROOT/versions\n"
  printf "  remove:     Remove symlink to specified Python version in \$PYENV_ROOT/versions\n"
  printf "  remove-all: Remove all pymac symlinks in \$PYENV_ROOT/versions\n"
  printf "  sync:       Symlink all Python.org installations to \$PYENV_ROOT/versions and\n"
  printf "              remove any dead symlinks\n"
}

pyenv-add() {
  local pyenv_versions_dir="$1"
  local py_version="$2"
  local py_dir=/Library/Frameworks/Python.framework/Versions/"$py_version"

  ln -s -f "$py_dir" "$pyenv_versions_dir/$py_version"
}

pyenv-remove() {
  local pyenv_versions_dir="$1"
  local py_version="$2"

  if [[ -L $pyenv_versions_dir/$py_version ]]; then
    rm "$pyenv_versions_dir/$py_version"
  else
    printf "No symlink to version %s found in %s\n" "$py_version" "$pyenv_versions_dir"
  fi
}

pyenv-remove-all() {
  local pyenv_versions_dir="$1"
  local py_version

  for dir in "$pyenv_versions_dir"/*; do
    py_version=$(basename "$dir")
    if [[ $py_version =~ ^[0-9][.][0-9]{1,2}$ ]]; then
      pyenv-remove "$pyenv_versions_dir" "$py_version"
    fi
  done
}

pyenv-sync() {
  local pyenv_versions_dir="$1"
  local py_root=/Library/Frameworks/Python.framework/Versions
  local py_version
  local symlink_dest

  # Loop through Python.org installs and create missing symlinks
  for dir in "$py_root"/*; do
    py_version=$(basename "$dir")
    if py_valid "$py_version"; then
      if [[ ! -L $pyenv_versions_dir/$py_version ]]; then
        pyenv-add "$pyenv_versions_dir" "$py_version"
      fi
    fi
  done

  # Loop through $PYENV_ROOT/versions and remove dead links named as Major.Minor
  for dir in "$pyenv_versions_dir"/*; do
    py_version=$(basename "$dir")
    if [[ -L $dir && $py_version =~ ^[0-9][.][0-9]{1,2}$ ]]; then
      symlink_dest=$(readlink "$dir")
      if [[ ! -d $symlink_dest ]]; then
        pyenv-remove "$pyenv_versions_dir" "$py_version"
      fi
    fi
  done
}

parse_args() {
  if command -v pyenv >/dev/null 2>&1; then
    local pyenv_versions_dir
    pyenv_versions_dir=$(pyenv root)/versions
  fi
  while :; do
    case "$1" in
      -h|help|--help|"")
        help
        break
        ;;
      add)
        if [[ -n "$pyenv_versions_dir" ]]; then
          if [[ -n "$2" ]] && py_valid "$2"; then
            IFS='.' read -ra PYVERSION <<< "$2"
            local py_version="${PYVERSION[0]}.${PYVERSION[1]}"
            if is_installed "$py_version"; then
              if [[ ${#PYVERSION[@]} -eq 3 ]]; then
                printf "Calling 'pymac pyenv add %s' instead (ignoring the Micro version you provided)\n" "$py_version"
              fi
              pyenv-add "$pyenv_versions_dir" "$py_version"
              break
            else
              printf "Python version %s not installed\n" "$py_version"
              return 1
            fi
          else
            printf "Please provide a valid Python version number.\n"
            return 1
          fi
        else
          printf "pyenv not installed.\n"
          return 1
        fi
        ;;
      remove)
        if [[ -n "$2" ]] && py_valid "$2"; then
          IFS='.' read -ra PYVERSION <<< "$2"
          local py_version="${PYVERSION[0]}.${PYVERSION[1]}"
          if [[ ${#PYVERSION[@]} -eq 3 ]]; then
            printf "Calling 'pymac pyenv remove %s' instead (ignoring the Micro version you provided)\n" "$py_version"
          fi
          pyenv-remove "$pyenv_versions_dir" "$py_version"
          break
        else
          printf "Please provide a valid Python version number.\n"
          return 1
        fi
        ;;
      remove-all|sync)
        if [[ -n "$pyenv_versions_dir" ]]; then
          pyenv-"$1" "$pyenv_versions_dir"
          break
        else
          printf "pyenv not installed.\n"
          return 1
        fi
        ;;
      *)
        printf "Invalid command. Check 'pymac pyenv help' for usage.\n"
        break
    esac
  done
}

parse_args "$@"
