# OPENSPEC:START
# OpenSpec shell completions configuration
fpath=("$HOME/.zsh/completions" $fpath)
autoload -Uz compinit
compinit
# OPENSPEC:END


export LANG=ja_JP.UTF-8
export EDITOR=micro

alias ls="ls -G"
alias ..="cd .."
alias ta="tmux attach -t claude"
alias y="yazi"

eval "$(/opt/homebrew/bin/brew shellenv)"
eval "$(mise activate zsh)"

eval "$(sheldon source)"
eval "$(starship init zsh)"

# https://github.com/junegunn/fzf?tab=readme-ov-file#setting-up-shell-integration
source <(fzf --zsh)

# carapace
export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
source <(carapace _carapace)


autoload -U +X bashcompinit && bashcompinit


export PATH="$HOME/.local/bin:$PATH"

eval "$(zoxide init zsh)"
