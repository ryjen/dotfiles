export PYENV_ROOT="$HOME/.pyenv"

if [ -d $PYENV_ROOT ]; then 
  export PATH="$PATH:$PYENV_ROOT/bin"
fi

type pyenv > /dev/null

if [ $? = 0 ]; then

  export PYTHON_CONFIGURE_OPTS="--enable-framework"
  eval "$(pyenv init -)"

fi

