OMZ_HOME="${HOME}/.oh-my-zsh"
OMZ_INIT="${HOME}/.oh-my-zsh/oh-my-zsh.sh"

[ -e ${OMZ_INIT} ] || exit 0

source $OMZ_INIT

zstyle :omz:plugins:keychain agents gpg,ssh
zstyle :omz:plugins:keychain options --quiet
zstyle :omz:plugins:ssh-agent agent-forwarding on

ZSH_THEME_GIT_PROMPT_CACHE=1

plugins=(ssh-agent last-working-dir taskwarrior autojump command-not-found colored-man-pages docker gpg-agent gnu-utils emoji sudo yarn react-native ansible colemak git-extras git-flow git-prompt extract encode64 gitignore golang keychain)

ZSH_DEFAULT_THEME_DIR="${OMZ_HOME}/custom/themes/powerlevel9k"

# Set name of the theme to load.
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="powerlevel9k/powerlevel9k"

POWERLEVEL9K_HISTORY_BACKGROUND='green'

POWERLEVEL9K_SHORTEN_STRATEGY="truncate_middle"
POWERLEVEL9K_SHORTEN_DIR_LENGTH=4


POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=''
POWERLEVEL9K_MULTILINE_SECOND_PROMPT_PREFIX="%F{red} \Uf1d0 %f %F{yellow
}❯ "

#POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(time context dir virtualenv vcs)
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir virtualenv vcs)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status history)
POWERLEVEL9K_SHORTEN_STRATEGY=truncate_middle
POWERLEVEL9K_SHORTEN_DELIMITER="*"
POWERLEVEL9K_PROMPT_ON_NEWLINE=true
POWERLEVEL9K_TIME_FORMAT='%D{%H:%M}'
POWERLEVEL9K_VIRTUALENV_BACKGROUND='150'  # Greenish

