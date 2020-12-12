if [ -f ~/.Xmodmap ]; then
  type xmodmap > /dev/null
  if [[ $? == 0 ]]; then
    xmodmap ~/.Xmodmap
  fi
fi

if type xdg-open > /dev/null; then
  alias open='xdg-open'
fi

if type xclip > /dev/null; then
  alias pbcopy='xclip -selection clipboard'
fi

