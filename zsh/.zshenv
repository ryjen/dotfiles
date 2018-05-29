# .zshenv is always sourced, define here exported variables that should
# be available to other programs.

export EDITOR=vim

export PATH=$PATH:$HOME/bin:/usr/local/bin

# load zsh config files

env_config_files=(~/.zsh/**/*.zshenv(N))
if test ! -z "$env_config_files" ;
    then
    for file in ${env_config_files}
    do
      source $file
    done
fi

