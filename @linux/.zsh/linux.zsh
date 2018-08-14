# GNU core utilities
eval `dircolors ~/.zsh/dircolors.256dark`      # colored ls

if [ -f ~/.Xmodmap ] && [ type xmodmap > /dev/null ]; then
  xmodmap ~/.Xmodmap
fi

if type xdg-open > /dev/null; then
  alias open='xdg-open'
fi 

if type xclip > /dev/null; then
  alias pbcopy='xclip -selection clipboard'
fi

