type lsd >/dev/null

if [ $? -eq 0 ]; then
  alias ls='lsd'
fi