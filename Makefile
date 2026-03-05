all:
	brew zsh starship git vscode claude mise yazi ghostty lazygit

.PHONY: brew
brew:
	sh brew/install.sh
	# 再起動しないとかも
	brew bundle --file ${PWD}/brew/Brewfile

.PHONY: zsh
zsh:
	ln -sf ${PWD}/zsh/.zshrc ${HOME}/.zshrc

.PHONY: starship
starship:
  # TODO: .config/starship.toml: No such file or directory
	ln -sf ${PWD}/starship/starship.toml ${HOME}/.config/starship.toml

.PHONY: git
git:
	ln -sf ${PWD}/git/.gitconfig ${HOME}/.gitconfig
	ln -sf ${PWD}/git/.git-commit-template.txt ${HOME}/.git-commit-template.txt
	mkdir -p ${HOME}/.config/git
	ln -sf ${PWD}/git/.gitignore ${HOME}/.config/git/ignore

.PHONY: vscode
vscode:
	ln -sf ${PWD}/vscode/settings.json ${HOME}/Library/Application\ Support/Code/User/settings.json

.PHONY: cursor
cursor:
	ln -sf ${PWD}/cursor/settings.json ${HOME}/Library/Application\ Support/Cursor/User/settings.json

.PHONY: claude
claude:
	mkdir -p ${HOME}/.claude
	ln -sf ${PWD}/claude/CLAUDE.md ${HOME}/.claude/CLAUDE.md
	ln -sfn ${PWD}/claude/commands ${HOME}/.claude/commands
	ln -sf ${PWD}/claude/skills/codex-review ${HOME}/.claude/skills/codex-review
	ln -sf ${PWD}/claude/settings.json ${HOME}/.claude/settings.json
	chmod +x ${PWD}/claude/statusline.sh
	ln -sf ${PWD}/claude/statusline.sh ${HOME}/.claude/statusline.sh

.PHONY: mise
mise:
	ln -sf ${PWD}/mise/config.toml ${HOME}/.config/mise/config.toml

.PHONY: yazi
yazi:
	mkdir -p ${HOME}/.config/yazi
	ln -sf ${PWD}/yazi/yazi.toml ${HOME}/.config/yazi/yazi.toml

.PHONY: ghostty
ghostty:
	mkdir -p ${HOME}/.config/ghostty
	ln -sf ${PWD}/ghostty/config ${HOME}/.config/ghostty/config

.PHONY: lazygit
lazygit:
	mkdir -p "${HOME}/Library/Application Support/lazygit"
	ln -sf ${PWD}/lazygit/config.yml "${HOME}/Library/Application Support/lazygit/config.yml"

dump-brew:
	brew bundle dump --file=${PWD}/brew/Brewfile --force --no-go
