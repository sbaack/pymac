#!/usr/bin/env bash

_pymac_list_versions() {
  pymac list 2>/dev/null
}

_pymac_list_pyenv_symlinks() {
  command -v pyenv >/dev/null 2>&1 || return
  local pyenv_root
  pyenv_root="$(pyenv root 2>/dev/null)/versions" || return
  local entry
  for entry in "$pyenv_root"/*; do
    [ -L "$entry" ] || continue
    local name
    name="$(basename "$entry")"
    if [[ "$name" =~ ^[0-9]\.[0-9]{1,2}$ ]]; then
      printf "%s\n" "$name"
    fi
  done
}

_pymac() {
  local cur prev words cword
  _init_completion || return

  local commands="certifi-update certifi-update-all clear-cache default default-which exec help install list pyenv uninstall update update-all upgrade"

  # Find the subcommand (first non-option word after pymac)
  local subcmd=""
  local i
  for ((i = 1; i < cword; i++)); do
    case "${words[i]}" in
    -*)
      continue
      ;;
    *)
      if [[ " $commands " == *" ${words[i]} "* ]]; then
        subcmd="${words[i]}"
        break
      fi
      ;;
    esac
  done

  # No subcommand yet — complete subcommands
  if [[ -z "$subcmd" ]]; then
    COMPREPLY=($(compgen -W "$commands" -- "$cur"))
    return
  fi

  case "$subcmd" in
  certifi-update)
    COMPREPLY=($(compgen -W "$(_pymac_list_versions)" -- "$cur"))
    ;;
  default | uninstall | update)
    COMPREPLY=($(compgen -W "$(_pymac_list_versions)" -- "$cur"))
    ;;
  exec)
    # Only complete version for the first argument after exec
    if [[ $((i + 1)) -eq $cword ]]; then
      COMPREPLY=($(compgen -W "$(_pymac_list_versions)" -- "$cur"))
    fi
    ;;
  default-which)
    COMPREPLY=($(compgen -W "--bare" -- "$cur"))
    ;;
  install)
    COMPREPLY=($(compgen -W "--default -d --interactive -i --keep -k" -- "$cur"))
    ;;
  list)
    COMPREPLY=($(compgen -W "--full -f" -- "$cur"))
    ;;
  pyenv)
    local pyenv_subcmds="add remove remove-all sync"
    local pyenv_subcmd=""
    local j
    for ((j = i + 1; j < cword; j++)); do
      if [[ " $pyenv_subcmds " == *" ${words[j]} "* ]]; then
        pyenv_subcmd="${words[j]}"
        break
      fi
    done

    if [[ -z "$pyenv_subcmd" ]]; then
      COMPREPLY=($(compgen -W "$pyenv_subcmds" -- "$cur"))
    elif [[ "$pyenv_subcmd" == "add" ]]; then
      COMPREPLY=($(compgen -W "$(_pymac_list_versions)" -- "$cur"))
    elif [[ "$pyenv_subcmd" == "remove" ]]; then
      COMPREPLY=($(compgen -W "$(_pymac_list_pyenv_symlinks)" -- "$cur"))
    fi
    ;;
  esac
}

complete -F _pymac pymac
