ZSH="${HOME}/.oh-my-zsh"
OMZ_INIT="${ZSH}/oh-my-zsh.sh"

if ! [[ -f $OMZ_INIT ]]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

  source $OMZ_INIT

  if [ -e $HOME/.zshrc.pre-on-my-zsh ]; then
    mv $HOME/.zshrc.pre-oh-my-zsh $HOME/.zshrc
  fi

  if ! [[ -d $ZSH_DEFAULT_THEME_DIR ]] && type git > /dev/null; then
      echo "Downloading oh-my-zsh default theme..."
      $(git clone https://github.com/bhilburn/powerlevel9k.git $ZSH_DEFAULT_THEME_DIR)
  fi

fi
