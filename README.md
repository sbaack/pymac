# pymac: Mac OS Python.org installs from the command line

`pymac` is a command line tool for installing and managing Python versions from Python.org's Mac installers.

Core features:

- Download and install Python.org versions entirely from the command line
- Installs only the basics (Python itself, Pip, and SSL certificates), other features like GUI applications are excluded (see [What is excluded](#what-is-excluded))
- Picks the latest known Python micro versions for you if you don't provide one
- Integrates with [pyenv](https://github.com/pyenv/pyenv) (allows you to manage Python versions installed with Python.org installers like normal pyenv installs)
- Various other conveniences to manage Python.org installations (e.g. setting default Python version, uninstalling versions, updating to latest known micro versions)

## Usage

First, an important note: With the Python.org installer, you always only have one Major.Minor Python version (e.g. 3.10). Different micro versions are not installed separately. That said, let's install a few Python versions:

```bash
pymac install 3.10 --default
pymac install 3.9.12
```

If you only provide Major.Minor versions, `pymac` will pick the latest known micro version for you. If you specify a micro version, this version will be picked instead. Python.org installers will install Python versions at `/Library/Frameworks/Python.framework/Versions/`, so your root password is required. Using the `--default` flag creates a symlink to `~/.config/pymac/default`, which you can add to your PATH so that the `python` or `pip` commands call this version of Python (see [Installation](#installation)). You can change the default any time:

```bash
pymac default 3.9
```

Please note that if you don't set a default, `pymac` only provides symlinks in `~/.local/bin` named "`pythonMajor.Minor`" (e.g. `python3.10`, see install below), no `python/pip` or `python3/pip3` commands are added to your PATH.

If you want to call a specific version of Python that is not set as default:

```bash
> pymac exec 3.10 --version
Python 3.10.4
> # If you have ~/.local/bin in your PATH you can also use:
> python3.10 --version
Python 3.10.4
```

Want to update to the latest known micro versions?

```bash
# Upgrade pymac itself first to make sure its internal list of latest known versions
# is up to date
pymac upgrade
pymac update 3.10
# Or check updates for all
pymac update-all
```

If there is a newer micro version available that `pymac` doesn't know about yet, just install it directly:

```bash
# This will override whatever 3.10 micro version you had installed before
pymac install 3.10.5
```

To see what micro versions are currently installed:

```bash
pymac list --full
3.10.4
3.9.12
```

Do you like to manage Python versions with [`pyenv`](https://github.com/pyenv/pyenv)?

```bash
pymac pyenv sync
```

This creates symlinks to `pymac` installs in `$PYENV_ROOT/versions`, which allows you to manage them with `pyenv`'s shims. `pymac` names its versions as Major.Minor to distinguish them from `pyenv` installs, which are named as Major.Minor.Micro:

```bash
# In this example we added pymac symlinks for 3.10 and 3.9
# Version 3.10.3 is a pyenv install
> pyenv versions
* system (set by /Users/stefan/.pyenv/version)
  3.10
  3.10.3
  3.9
> pyenv global 3.10
> pyenv versions
  system
* 3.10 (set by /Users/stefan/.pyenv/version)
  3.10.3
  3.9
```

To remove symlinks to pyenv:

```bash
# Remove a specific version or all
pymac pyenv remove 3.9
pymac pyenv remove-all
```
See the [List of commands](#list-of-commands) for more options.

## Installation

Clone this repository:

```bash
git clone https://github.com/sbaack/pymac.git ~/.pymac
```

Add the following to your `~/.zshrc` or `~/.bashrc`:

```bash
export PATH=~/.pymac/bin:"$PATH"
# Optional: Add pymac default to your PATH
export PATH=~/.config/pymac/default/bin:"$PATH"
# Optional: Add ~/.local/bin to your PATH if you haven't already
export PATH=~/.local/bin:"$PATH"
```

For fish, add this to your `~/.config/fish/config.fish`:

```bash
set -x PATH ~/.pymac/bin "$PATH"
# Optional: Add pymac default to your PATH
set -x PATH ~/.config/pymac/default/bin "$PATH"
# Optional: Add ~/.local/bin to your PATH if you haven't already
set -x PATH ~/.local/bin "$PATH"
```

For fish completions:

```bash
mkdir -p ~/.config/fish/completions; and ln -s -f ~/.pymac/completions/pymac.fish ~/.config/fish/completions/
```

Adding `~/.config/pymac/default/bin` to your PATH is entirely optional. You can also call `pymac` Python installations directly with the `pymac exec` command. If you would like to be able to call or specify a Python version with `pythonMajor.Minor` (e.g. `python3.10`), make sure to add `~/.local/bin` to your PATH. Also ensure that `~/.local/bin` is in your PATH before `/usr/local/bin` because this is where Homebrew stores `pythonMajor.Minor` symlinks itself. Having `~/.local/bin` in your PATH before `/usr/local/bin` means that `pymac`'s Python versions are preferred over Homebrew if you have a Python version installed in both.

Note: If you want to manage `pymac` installs with `pyenv` you should source `pyenv` _after_ adding `~/.config/pymac/default/bin` to your PATH.

## Why?

In short, because the Python.org installers have some advantages over other solutions:

- You don't need to compile Python yourself. `pyenv` or `asdf-python` are great, but both require you to install Python build dependencies, and building Python might fail when you upgrade Mac OS and/or your device.
- If you typically just want the latest micro versions of Python, Python.org installations have the advantage that existing Major.Minor versions are updated in-place. This means you only have one Python version 3.10 or 3.11 for example. If you update Python 3.10.2 to 3.10.3 with the Python.org installer, 3.10.3 will override 3.10.2. Unless a micro version update of Python breaks your dependencies, the virtualenvs you've created with 3.10.2 will continue to work because they point to the same (updated) '3.10' directory.
- [Unlike Homebrew Python](https://justinmayer.com/posts/homebrew-python-is-not-for-you/), installations from Python.org won't randomly break your virtualenvs because you stay in control of when and how Python versions are updated.

`pymac` is about utilizing the advantages of Python.org installers while mitigating some of their inconveniences:

- The most obvious one being that you usually have to visit Python.org, download the version you need, and click through a GUI interface.
- Python.org installers by default also install features that you might not want: GUI applications, shell config manipulations, documentation and more (see [What is excluded](#what-is-excluded))
- Python.org installers come with their own private copy of OpenSSL and require you to manually execute a command that installs and sets up SSL root certificates from the [`certifi` package](https://pypi.org/project/certifi/). This command only comes with the GUI applications.

`pymac` mitigates this by a) enabling you to install Python.org versions entirely from the command line, b) customizing the installer to only install the basics: Python itself and Pip, and c) automatically installing and setting up SSL certificates. In addition, it offers commands to help manage multiple versions of Python. See [How it works](#how-it-works) and the [List of commands](#list-of-commands) for more information.

## How it works

When you install a Python version with `pymac` the following happens in the background:

1. Download the correct PKG installer from Python.org.
2. Install Python using the PKG file from the command line (no GUI). Your root password will be required to install Python in `/Library/Frameworks/Python.framework/Versions/<Major.Minor>` (unfortunately you can't customize the location). `pymac` customizes the installation so that only Python itself and Pip are installed (see [What is excluded](#what-is-excluded)).
3. Additional symlinks are created. First, Python.org installers only include executables named `python3` or `pip3` by default. `pymac` creates additional symlinks in Python's 'bin' directory so that the default names are used as well (`python`, `pip` etc.). Second, the Python.org installers optionally create `pythonMajor.Minor` symlinks (e.g. `python3.10`) in `/usr/local/bin` to make calling or specifying a Python version easier (if 'UNIX command line tools' are installed, they are excluded by `pymac`. See [What is excluded](#what-is-excluded)). Putting such symlinks in `/usr/local/bin` might conflict with Homebrew Python. `pymac` avoids conflicts by creating `pythonMajor.Minor` symlinks in `~/.local/bin` instead.
4. Finally, `pymac` will automatically install and symlink SSL root certificates from the [`certifi` package](https://pypi.org/project/certifi/). This replicates the `Install Certificates.command` that comes with the GUI applications from the Python.org installer (which `pymac` doesn't install) and that you typically have to execute manually after the installation is completed.

## What is excluded

The following features of the Python.org installer are excluded:

- GUI Applications: Adds a directory in `/Applications` with the Python Launcher (enables double-clicking Python scripts in Finder), some scripts (for setting up SSL certificates and the shell profile updater) and a shortcut to IDLE. Note that you can still run IDLE from the command line when GUI applications are not installed.
- UNIX command line tools: Adds symlinks to Python executables to `/usr/local/bin`.
- Python Documentation: Offline documentation.
- Shell profile updater: Adds a line to your shell config (`.bash_profile`, `.zprofile`, or `config.fish`) that prepends the installed Python version to your PATH.

If you need any of these features, `pymac` can still be useful for you. First, you can use it to download the installer using the `--keep` flag:

```bash
pymac install 3.10 --keep
```

After the download is completed, you can cancel `pymac`'s install process when you're asked for you root password and manually open the GUI installer stored in `~/.pymac/cache` instead. Once installed, `pymac` can still be used to manage your Python installation(s), e.g. to install or update SSL certificates or to uninstall a Python version. Also note that you can remove the downloaded PKG installer(s) with `pymac clear-cache`.

## List of commands

```
> pymac help
Install and manage Python.org Mac installers from the command line.

Usage: pymac <command> [<args>]

Commands:
  certifi-update: Update/install and symlink SSL certificates in specified Python version
  clear-cache:    Delete downloaded PKG installers
  default:        Set Python version symlinked to ~/.config/pymac/default
  default-which:  Show path to Python version symlinked to ~/.config/pymac/default
  exec:           Directly call specified Python version
  install:        Download and (re)install Python version
  list:           List Python versions installed via Python.org installer
  pyenv:          Manage symlinks of Python.org installations in $PYENV_ROOT/versions
  uninstall:      Remove Python version
  update:         Update specified Python to the latest known Micro version (e.g. updates 3.10.1 to 3.10.2)
  update-all:     Update all pymac installs to latest known Micro versions
  upgrade:        Update pymac itself to the latest HEAD version

See 'pymac <command> help' for more information.
```
