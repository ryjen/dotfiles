# .zshenv is always sourced, define here exported variables that should
# be available to other programs.

export PAGER=less

type nvim > /dev/null

if [ $? -eq 0 ]; then
  export EDITOR=nvim
else
  export EDITOR=vim
fi

export VISUAL=$EDITOR
export GIT_EDITOR=$EDITOR

export PATH=$PATH:$HOME/.local/bin:/usr/local/bin

# load zsh config files
#autoload -Uz compinit && compinit

env_config_files=(~/.zsh/**/*.zshenv(N))
if test ! -z "$env_config_files" ;
    then
    for file in ${env_config_files}
    do
      source $file
    done
fi

# remove dups in path
typeset -U PATH

