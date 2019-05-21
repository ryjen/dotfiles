
type gdircolors &> /dev/null

if [[ $? == 0 ]]; then
  # GNU core utilities
  eval `gdircolors ~/.zsh/dircolors.256dark`      # colored ls
  alias ls="gls --color --group-directories-first --ignore='.|..'"
fi

