type lsd 2>&1 >/dev/null

if [ $? -eq 0 ]; then
  alias ls='lsd'
fi