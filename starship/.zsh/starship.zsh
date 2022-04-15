type starship >/dev/null 2>&1

if [ $? -eq 0 ]; then
  eval "$(starship init zsh)"
fi