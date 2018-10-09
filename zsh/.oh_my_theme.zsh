ZSH_DEFAULT_THEME_DIR="$HOME/.oh-my-zsh/custom/themes/powerlevel9k"

if ! [[ -d $ZSH_DEFAULT_THEME_DIR ]] &&type git > /dev/null; then
    echo "Downloading oh-my-zsh default theme..."
    $(git clone https://github.com/bhilburn/powerlevel9k.git $ZSH_DEFAULT_THEME_DIR)
    if ! [[ $? -eq 0 ]]; then
        echo "Unable download theme"
    fi
fi


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
POWERLEVEL9K_CUSTOM_BOOBS="boobify"

boobify() {
    echo -n "( . Y . )"
}

