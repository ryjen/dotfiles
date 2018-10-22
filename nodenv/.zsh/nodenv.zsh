type nodenv > /dev/null

if [ $? = 0 ]; then

  eval "$(nodenv init -)"
  export PATH=$HOME/.nodenv/bin:$PATH

fi

