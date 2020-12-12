type goenv > /dev/null

if [ $? -eq 0 ]; then

  export GOENV_DISABLE_GOPATH=1
  export GOENV_GOPATH_PREFIX=$HOME/Source/go
  eval "$(goenv init -)"
  export PATH=$GOENV_ROOT/bin:$PATH
  export GOROOT="$(goenv prefix)"

fi

