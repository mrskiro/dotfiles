#!/usr/bin/env bash
# 新PCの初期ブートストラップ
# Homebrew → 最低限アプリ (Chrome, Bitwarden) → Claude Code
# このスクリプトは dotfiles clone "前" に走らせる想定。
#
# 使い方:
#   curl -fsSL https://raw.githubusercontent.com/mrskiro/dotfiles/main/scripts/bootstrap.sh | bash
# または既に clone 済なら:
#   bash ~/.local/share/chezmoi/scripts/bootstrap.sh

set -euo pipefail

echo "==> Homebrew"
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
# Apple Silicon の brew を PATH へ
eval "$(/opt/homebrew/bin/brew shellenv)"

echo "==> Chrome / Bitwarden (Brewfile より先に単独 install)"
brew install --cask google-chrome bitwarden

cat <<'MSG'

==> 手動ステップ:
   1. Chrome を起動してメインアカウントでログイン
   2. Bitwarden デスクトップでログイン
   3. Chrome 拡張 Bitwarden を入れてログイン
   終わったら Enter で続行 (Ctrl+C で中断可)
MSG
read -r

echo "==> Claude Code (curl 公式インストーラー)"
curl -fsSL https://claude.ai/install.sh | bash

cat <<'MSG'

==> Bootstrap 完了。次にやること:

   gh auth login
   git clone https://github.com/mrskiro/dotfiles.git ~/.local/share/chezmoi
   chezmoi apply
   brew bundle --file ~/.local/share/chezmoi/brew/Brewfile
   ya pkg install                                # yazi プラグイン取得
   bash ~/.local/share/chezmoi/scripts/macos-defaults.sh

   詳細は docs/mac-setup.md を参照。
MSG
