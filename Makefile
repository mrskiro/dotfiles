all:
	brew zsh starship git vscode claude

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
	npm install -g @anthropic-ai/claude-code
	ln -sf ${PWD}/claude/CLAUDE.md ${HOME}/.claude/CLAUDE.md
	ln -sf ${PWD}/claude/commands ${HOME}/.claude/commands
	ln -sf ${PWD}/claude/settings.json ${HOME}/.claude/settings.json

dump-brew:
	brew bundle dump --file=${PWD}/brew/Brewfile --force