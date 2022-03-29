function __list-latest-versions
    # For 'pymac install': Autocomplete Major.Minor versions listed in $PYMAC_ROOT/latest_versions
    set -l pymac_dir
    if test -n "$PYMAC_ROOT"
        set pymac_dir $PYMAC_ROOT
    else
        set pymac_dir ~/.pymac
    end
    set -l py_versions $pymac_dir/latest_versions/*

    for py_version in $py_versions
        printf "%s\n" (basename $py_version)
    end
end

function __list-pyenv-symlinks
    # For 'pymac pyenv remove': Autocomplete pymac symlinks in $PYENV_ROOT/versions
    if not type -q pyenv
        return
    end
    set -l pyenv_versions (pyenv root)/versions/*
    for path in $pyenv_versions
        set py_version (basename $path)
        # Only add to autocompletion list if basename of dir matches Python Major.Minor version
        # and if file is a symlink
        if string match -q -r '^[0-9][.][0-9]{1,2}$' $py_version
            if test -L $path
                printf "%s\n" $py_version
            end
        end
    end
end

# Top-level commands
set -l pymac_commands add-certs clear-cache default default-which \
    exec help install list pyenv uninstall update update-all upgrade

complete -f -c pymac -n "not __fish_seen_subcommand_from $pymac_commands" \
    -a add-certs \
    -d 'Install and symlink root certificates'
complete -f -c pymac -n "not __fish_seen_subcommand_from $pymac_commands" \
    -a clear-cache \
    -d "Delete downloaded PKG installers"
complete -f -c pymac -n "not __fish_seen_subcommand_from $pymac_commands" \
    -a default \
    -d "Set Python version symlinked to ~/.config/pymac/default"
complete -f -c pymac -n "not __fish_seen_subcommand_from $pymac_commands" \
    -a default-which \
    -d "Show Python version symlinked to ~/.config/pymac/default"
complete -f -c pymac -n "not __fish_seen_subcommand_from $pymac_commands" \
    -a exec \
    -d "Directly call specified Python version"
complete -f -c pymac -n "not __fish_seen_subcommand_from $pymac_commands" \
    -a help \
    -d "Show help"
complete -f -c pymac -n "not __fish_seen_subcommand_from $pymac_commands" \
    -a install \
    -d "Download and (re)install Python version"
complete -f -c pymac -n "not __fish_seen_subcommand_from $pymac_commands" \
    -a list \
    -d "List Python versions installed via Python.org installer"
complete -f -c pymac -n "not __fish_seen_subcommand_from $pymac_commands" \
    -a pyenv \
    -d "Manage symlinks of Python.org installations in \$PYENV_ROOT/versions"
complete -f -c pymac -n "not __fish_seen_subcommand_from $pymac_commands" \
    -a uninstall \
    -d "Remove Python version"
complete -f -c pymac -n "not __fish_seen_subcommand_from $pymac_commands" \
    -a update \
    -d "Update specified Python to the latest known Micro version (e.g. updates 3.10.1 to 3.10.2)"
complete -f -c pymac -n "not __fish_seen_subcommand_from $pymac_commands" \
    -a update-all \
    -d "Update all pymac installs to latest known Micro versions"
complete -f -c pymac -n "not __fish_seen_subcommand_from $pymac_commands" \
    -a upgrade \
    -d "Update pymac itself to the latest HEAD version"

# Command arguments
complete -x -c pymac -n "__fish_seen_subcommand_from add-certs; \
    and not __fish_seen_subcommand_from (pymac list)" \
    -a "(pymac list)"
complete -x -c pymac -n "__fish_seen_subcommand_from default; \
    and not __fish_seen_subcommand_from (pymac list)" \
    -a "(pymac list)"
complete -x -c pymac -n "__fish_seen_subcommand_from exec; \
    and not __fish_seen_subcommand_from (pymac list)" \
    -a "(pymac list)"
complete -x -c pymac -n "__fish_seen_subcommand_from uninstall; \
    and not __fish_seen_subcommand_from (pymac list)" \
    -a "(pymac list)"
complete -x -c pymac -n "__fish_seen_subcommand_from update; \
    and not __fish_seen_subcommand_from (pymac list)" \
    -a "(pymac list)"
complete -x -c pymac -n "__fish_seen_subcommand_from list" \
    -a --full \
    -d "Also show full version number (with micro version)"
complete -x -c pymac -n "__fish_seen_subcommand_from install; \
    and not __fish_seen_subcommand_from (__list-latest-versions)" \
    -a "(__list-latest-versions)"

# 'pymac pyenv' command: Add extra completions for 'pymac pyenv add' and 'pymac pyenv remove'
set -l pyenv_add_remove add remove

complete -x -c pymac -n "__fish_seen_subcommand_from pyenv; \
    and __fish_seen_subcommand_from add; \
    and not __fish_seen_subcommand_from (pymac list)" \
    -a "(pymac list)"

complete -x -c pymac -n "__fish_seen_subcommand_from pyenv; \
    and __fish_seen_subcommand_from remove \
    and not __fish_seen_subcommand_from (__list-pyenv-symlinks)" \
    -a "(__list-pyenv-symlinks)"
complete -x -c pymac -n "__fish_seen_subcommand_from pyenv; \
    and not __fish_seen_subcommand_from $pyenv_add_remove" \
    -a add \
    -d "Create symlink to specified Python version in \$PYENV_ROOT/versions"
complete -x -c pymac -n "__fish_seen_subcommand_from pyenv; \
    and not __fish_seen_subcommand_from $pyenv_add_remove" \
    -a remove \
    -d "Remove symlink to specified Python version in \$PYENV_ROOT/versions"
complete -x -c pymac -n "__fish_seen_subcommand_from pyenv; \
    and not __fish_seen_subcommand_from $pyenv_add_remove" \
    -a remove-all \
    -d "Remove all pymac symlinks in \$PYENV_ROOT/versions"
complete -x -c pymac -n "__fish_seen_subcommand_from pyenv; \
    and not __fish_seen_subcommand_from $pyenv_add_remove" \
    -a sync \
    -d "Symlink all Python.org installations to \$PYENV_ROOT/versions and remove any dead symlinks"

# 'pymac install': Offer optional args after Python version number was provided
complete -x -c pymac -n "__fish_seen_subcommand_from install; \
    and __fish_seen_subcommand_from (__list-latest-versions)" \
    -a --default \
    -d "Symlink Python version to ~/.config/pymac/default after install"
complete -x -c pymac -n "__fish_seen_subcommand_from install; \
    and __fish_seen_subcommand_from (__list-latest-versions)" \
    -a --keep \
    -d "Do not delete PKG file after install completed, keep it in \$PYMAC_ROOT/cache"
