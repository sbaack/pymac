#compdef pymac

_pymac_list_versions() {
  local -a versions
  versions=(${(f)"$(pymac list 2>/dev/null)"})
  compadd -a versions
}

_pymac_list_pyenv_symlinks() {
  (( $+commands[pyenv] )) || return
  local pyenv_root
  pyenv_root="$(pyenv root 2>/dev/null)/versions" || return
  local -a symlinks
  local entry name
  for entry in "$pyenv_root"/*; do
    [[ -L "$entry" ]] || continue
    name="${entry:t}"
    if [[ "$name" =~ '^[0-9]\.[0-9]{1,2}$' ]]; then
      symlinks+=("$name")
    fi
  done
  compadd -a symlinks
}

_pymac() {
  local -a subcommands
  subcommands=(
    'certifi-update:Update/install and symlink SSL certificates in specified Python version'
    'certifi-update-all:Update certifi package for all Python versions installed via pymac'
    'clear-cache:Delete downloaded PKG installers'
    'default:Set Python version symlinked to ~/.config/pymac/default'
    'default-which:Show Python version symlinked to ~/.config/pymac/default'
    'exec:Directly call specified Python version'
    'help:Show help'
    'install:Download and (re)install Python version'
    'list:List Python versions installed via Python.org installer'
    'pyenv:Manage symlinks of Python.org installations in $PYENV_ROOT/versions'
    'self-update:Update pymac itself to the latest HEAD version'
    'uninstall:Remove Python version'
    'update:Update specified Python to the latest available Micro version'
    'update-all:Update all pymac installs to latest available Micro versions'
  )

  _arguments -C \
    '1:command:->command' \
    '*::arg:->args'

  case "$state" in
  command)
    _describe -t commands 'pymac command' subcommands
    ;;
  args)
    case "${words[1]}" in
    certifi-update)
      _arguments '1:version:_pymac_list_versions'
      ;;
    default | uninstall | update)
      _arguments '1:version:_pymac_list_versions'
      ;;
    exec)
      _arguments '1:version:_pymac_list_versions' '*:arguments:_files'
      ;;
    default-which)
      _arguments '--bare[Only show version number instead of full path]'
      ;;
    install)
      _arguments \
        '(--default -d)'{--default,-d}'[Symlink Python version to ~/.config/pymac/default after install]' \
        '(--interactive -i)'{--interactive,-i}'[Open the PKG in macOS Installer instead of installing via command line]' \
        '(--keep -k)'{--keep,-k}'[Do not delete PKG file after install completed]' \
        '1:version:'
      ;;
    list)
      _arguments '(--full -f)'{--full,-f}'[Also show full version number (with micro version)]'
      ;;
    pyenv)
      local -a pyenv_subcmds
      pyenv_subcmds=(
        'add:Create symlink to specified Python version in $PYENV_ROOT/versions'
        'remove:Remove symlink to specified Python version in $PYENV_ROOT/versions'
        'remove-all:Remove all pymac symlinks in $PYENV_ROOT/versions'
        'sync:Symlink all Python.org installations and remove dead symlinks'
      )
      _arguments -C \
        '1:pyenv command:->pyenv_command' \
        '*::pyenv arg:->pyenv_args'
      case "$state" in
      pyenv_command)
        _describe -t pyenv-commands 'pyenv subcommand' pyenv_subcmds
        ;;
      pyenv_args)
        case "${words[1]}" in
        add)
          _arguments '1:version:_pymac_list_versions'
          ;;
        remove)
          _arguments '1:version:_pymac_list_pyenv_symlinks'
          ;;
        esac
        ;;
      esac
      ;;
    esac
    ;;
  esac
}

# When sourced directly, register the completion; when called by
# the completion system, _pymac runs automatically via compdef.
if (( ${+functions[compdef]} )); then
  compdef _pymac pymac
elif (( ${+functions[_comps]} )); then
  _comps[pymac]=_pymac
fi
