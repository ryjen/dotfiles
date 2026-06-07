# .zshenv is always sourced, define here exported variables that should
# be available to other programs.
export ZDOTDIR=~/.config/zsh

export PATH=$PATH:$HOME/.local/bin:/usr/local/bin

# load zsh config files
autoload -Uz compinit && compinit

# remove dups in path
typeset -U PATH
