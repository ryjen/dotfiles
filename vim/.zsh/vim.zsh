
if type_exists nvim; then
  alias vim='nvim'
  alias svim='nvim "+let g:isSlim = 1"'
  export EDITOR=nvim
else
  alias svim='vim "+let g:isSlim = 1"'
  export EDITOR=vim
fi

