
if [ -d "$HOME/.exenv/bin" ]; then
  PATH="$HOME/.exenv/bin:$PATH"

  eval "$(exenv init -)"
fi
