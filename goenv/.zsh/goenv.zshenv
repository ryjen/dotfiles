
if [ ! -d $HOME/.goenv ]; then
  type git &> /dev/null && git clone https://github.com/syndbg/goenv.git $HOME/.goenv
fi

export GOENV_ROOT=$HOME/.goenv
export PATH=$GOENV_ROOT/bin:$PATH
export GOENV_DISABLE_GOPATH=1
eval "$(goenv init -)"

