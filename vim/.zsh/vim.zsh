
if type_exists nvim; then
  alias vim='nvim'
  alias svim='nvim "+let g:isSlim = 1"'
  export EDITOR=nvim
  export VISUAL=nvim
  export GIT_EDITOR=nvim
else
  alias svim='vim "+let g:isSlim = 1"'
  export EDITOR=vim
  export VISUAL=vim
  export GIT_EDITOR=vim
fi

