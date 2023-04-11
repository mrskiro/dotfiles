all:
	brew zsh starship git

.PHONY: brew
brew:
	sh brew/install.sh
	brew bundle --file ${PWD}/brew/Brewfile

.PHONY: zsh
zsh:
	ln -sf ${PWD}/zsh/.zshrc ${HOME}/.zshrc

.PHONY: starship
starship:
	ln -sf ${PWD}/starship/starship.toml ${HOME}/.config/starship.toml

.PHONY: git
git:
	ln -sf ${PWD}/git/.gitconfig ${HOME}/.gitconfig
	ln -sf ${PWD}/git/.git-commit-template.txt ${HOME}/.git-commit-template.txt