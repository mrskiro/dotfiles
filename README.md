# dotfiles for macOS

Managed with [chezmoi](https://www.chezmoi.io/).

## Setup (new machine)

```sh
# 1. Bootstrap: Homebrew + Chrome + Bitwarden + Claude Code
curl -fsSL https://raw.githubusercontent.com/mrskiro/dotfiles/main/scripts/bootstrap.sh | bash

# 2. Point chezmoi at ~/mrskiro/dotfiles (デフォルトの ~/.local/share/chezmoi は使わない)
mkdir -p ~/.config/chezmoi
printf 'sourceDir   = "~/mrskiro/dotfiles"\nworkingTree = "~/mrskiro/dotfiles"\n' > ~/.config/chezmoi/chezmoi.toml

# 3. Clone dotfiles
gh auth login
git clone https://github.com/mrskiro/dotfiles.git ~/mrskiro/dotfiles

# 4. Install packages from Brewfile
brew bundle --file ~/mrskiro/dotfiles/brew/Brewfile

# 5. Apply dotfiles
chezmoi apply

# 6. macOS defaults (trackpad / keyboard / Dock / power)
bash ~/mrskiro/dotfiles/scripts/macos-defaults.sh

# 7. Default applications for file extensions
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
