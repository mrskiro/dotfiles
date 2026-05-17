# dotfiles for macOS

Managed with [chezmoi](https://www.chezmoi.io/).

## Setup (new machine)

```sh
# 1. Bootstrap: Homebrew + Chrome + Bitwarden + Claude Code
curl -fsSL https://raw.githubusercontent.com/mrskiro/dotfiles/main/scripts/bootstrap.sh | bash

# 2. Clone dotfiles
gh auth login
git clone https://github.com/mrskiro/dotfiles.git ~/.local/share/chezmoi

# 3. Install packages from Brewfile
brew bundle --file ~/.local/share/chezmoi/brew/Brewfile

# 4. Apply dotfiles
chezmoi apply

# 5. macOS defaults (trackpad / keyboard / Dock / power)
bash ~/.local/share/chezmoi/scripts/macos-defaults.sh

# 6. Default applications for file extensions
pkgx duti ~/.duti
```

詳細手順とアプリ個別設定は [docs/mac-setup.md](docs/mac-setup.md) を参照。

## Layout

- `dot_*`, `private_*`: chezmoi が `~/` に apply するファイル
- `brew/Brewfile`: パッケージ一覧
- `scripts/`: ブートストラップと macOS defaults
- `docs/`: セットアップメモ等

## Brew

```sh
# Dump current packages to Brewfile
brew bundle dump --file brew/Brewfile --force --no-go
```
