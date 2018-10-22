
type rbenv > /dev/null

if [ $? = 0 ]; then

  eval "$(rbenv init -)"
  export PATH=${HOME}/.rbenv/shims:$PATH

fi
