#!/usr/bin/env bash
# macOS defaults for new machine setup
# 詳細は docs/mac-setup.md を参照
#
# 使い方:
#   bash ~/.local/share/chezmoi/scripts/macos-defaults.sh
#
# 反映タイミング:
#   - Dock 系は即時 (killall Dock)
#   - トラックパッド/キーボード系は再ログインで反映
#   - pmset は sudo 必須

set -euo pipefail

echo "==> Trackpad"
defaults write -g com.apple.trackpad.scaling -float 3.0
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write -g com.apple.mouse.tapBehavior -int 1
defaults write -g com.apple.swipescrolldirection -bool false   # ナチュラルスクロール OFF

echo "==> Keyboard / Input"
defaults write com.apple.HIToolbox AppleFnUsageType -int 0
defaults write -g TISRomanSwitchState -bool true
defaults write -g NSAutomaticCapitalizationEnabled -bool false
defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false
defaults write com.apple.inputmethod.Kotoeri JIMPrefAutocorrectionKey -int 0
defaults write com.apple.inputmethod.Kotoeri JIMPrefLiveConversionKey -int 0

echo "==> Dock"
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock tilesize -int 16
defaults write com.apple.dock magnification -bool true
defaults write com.apple.dock largesize -int 64
killall Dock

echo "==> Power (sudo required)"
sudo pmset -b displaysleep 30
sudo pmset -c displaysleep 0

echo "Done. 再ログインで全項目反映されます。"
