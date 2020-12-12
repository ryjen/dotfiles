if [ -d $HOME/.jenv/bin ]; then
  export PATH="$HOME/.jenv/bin:$PATH"
fi

type jenv > /dev/null

if [ $? -eq 0 ]; then
  eval "$(jenv init -)"
fi
