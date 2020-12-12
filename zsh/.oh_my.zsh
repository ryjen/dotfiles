# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

ZSH_INIT=$ZSH/oh-my-zsh.sh

if ! [[ -f $ZSH_INIT ]]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
    mv $HOME/.zshrc.pre-oh-my-zsh $HOME/.zshrc
fi

source $HOME/.oh_my_theme.zsh

source $HOME/.oh_my_plugins.zsh

source $ZSH_INIT

if ! [[ -d $ZSH_DEFAULT_THEME_DIR ]] && type git > /dev/null; then
    echo "Downloading oh-my-zsh default theme..."
    $(git clone https://github.com/bhilburn/powerlevel9k.git $ZSH_DEFAULT_THEME_DIR)
fi

