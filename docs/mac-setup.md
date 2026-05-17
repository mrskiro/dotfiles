# macOS セットアップ手順

新しい Mac を買ったときに上から順にやる。

## 0. 前提

- Apple Silicon Mac
- 個人 Apple ID を持っている
- Bitwarden アカウントを持っている

## 1. 初回起動 (Setup Assistant)

- 言語: 日本語
- Apple ID でサインイン
- Touch ID 登録
- FileVault 有効化（回復キーは Bitwarden へ）

## 2. Bootstrap（Homebrew + Chrome + Bitwarden + Claude Code）

Safari から dotfiles リポを開き、bootstrap スクリプトをワンライナーで実行:

```sh
curl -fsSL https://raw.githubusercontent.com/mrskiro/dotfiles/main/scripts/bootstrap.sh | bash
```

このスクリプトの中で:

1. Homebrew install
2. Chrome / Bitwarden を単独 install（`brew bundle` より先に）
3. **手動で待ち**: Chrome ログイン / Bitwarden デスクトップ + Chrome拡張ログイン
4. Claude Code を curl 公式インストーラーで install（brew は使わない）

ここまでで必要なパスワードを Bitwarden から取り出せる + Claude Code が `claude` で起動できる状態。

## 3. dotfiles を clone

```sh
gh auth login   # まだなら
# gh が未インストールなら一時的に: brew install gh

git clone https://github.com/mrskiro/dotfiles.git ~/.local/share/chezmoi
```

> 以降のコマンドは `~/.local/share/chezmoi` を chezmoi の source として参照する前提。

## 4. 残りのアプリを brew bundle

```sh
brew bundle --file ~/.local/share/chezmoi/brew/Brewfile
```

## 5. chezmoi で dotfiles を apply

```sh
# Bitwarden CLI を unlock (templates が bw を参照する場合)
export BW_SESSION=$(bw unlock --raw)

chezmoi apply
```

## 6. mise

```sh
mise upgrade            # mise 本体を最新化
mise install            # ~/.mise.toml があれば言語ランタイムを一括 install
```

## 7. yazi プラグイン

`package.toml` は chezmoi apply で配置済みだが、プラグイン本体（`~/.config/yazi/plugins/`）は別途取得が必要:

```sh
ya pkg install
```

## 8. macOS 設定 (defaults / pmset)

GUI でポチポチやらず一括スクリプトで:

```sh
bash ~/.local/share/chezmoi/scripts/macos-defaults.sh
```

内容（トラックパッド・キーボード・Dock・電源）は `scripts/macos-defaults.sh` を参照。
pmset の sudo パスワード入力プロンプトが出る。再ログインで全項目反映。

## 9. アプリ個別設定（手作業）

- Raycast: 初回起動時の対話で Spotlight (`Cmd+Space`) を自動で奪うので、画面の指示に従うだけでOK。無料プランなのでクラウド sync は使えず、毎回手動セットアップで割り切る。
  - カレンダー連携: macOS 純正カレンダーに Google Calendar を登録 → Raycast の Calendar 拡張で予定確認 + ミーティングの Auto-join を ON
  - Window Management: Right Half / Left Half にショートカット割当
  - Clipboard History: ショートカット割当
  - 拡張: Kill Process を追加
  - 参考: Settings → Advanced → **Export Settings & Data** で `.rayconfig` 書き出し可能（PGP暗号化）。必要になったら使う
- Dock 整理: Keynote / マップ等の未使用アイコンを削除、よく使うアプリは追加
- VS Code: Settings Sync (GitHub) でログイン
- cmux (ターミナル): Ghostty ベース。v0.64.0 以降は `~/.config/ghostty/config` に `theme = ...` を明示しないと cmux独自デフォルト（白背景）になる。dotfiles 側で `theme = Ghostty Default Style Dark` を指定済なので、chezmoi apply 後に cmux 再起動すれば反映

## 10. 動作確認

```sh
chezmoi doctor
brew bundle check --file ~/.local/share/chezmoi/brew/Brewfile
gh auth status
claude --version
mise --version
```

---

## defaults キーが不明な設定を特定する方法

GUI でポチる前後で plist を diff すると確実に分かる:

```sh
# before
mkdir -p /tmp/plist && defaults read com.apple.<対象> > /tmp/plist/before.txt

# GUI で設定変更

# after
defaults read com.apple.<対象> > /tmp/plist/after.txt
diff /tmp/plist/before.txt /tmp/plist/after.txt
```

NSGlobalDomain 全体を `defaults read NSGlobalDomain | grep -i <キーワード>` で
眺めるのも有効（例: Caps Lock 設定の `TISRomanSwitchState` はこれで見つけた）。
