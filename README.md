# dotfiles for macOS

Managed with [chezmoi](https://www.chezmoi.io/).

## Setup (new machine)

```shell
# 1. Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install packages from Brewfile
brew bundle --file brew/Brewfile

# 3. Apply dotfiles
chezmoi init --apply mrskiro/dotfiles

# 4. Set default applications for file extensions
pkgx duti ~/.duti
```

## Brew

```shell
# Dump current packages to Brewfile
brew bundle dump --file brew/Brewfile --force --no-go
```
