all:
	brew zsh starship git vscode

.PHONY: brew
brew:
	sh brew/install.sh
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

.PHONY: vscode
vscode:
	ln -sf ${PWD}/vscode/settings.json ${HOME}/Library/Application\ Support/Code/User/settings.json

dump-brew:
	brew bundle dump --file=${PWD}/brew/Brewfile --force