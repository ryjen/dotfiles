type pyenv > /dev/null

if [ $? = 0 ]; then

  export PYTHON_CONFIGURE_OPTS="--enable-framework"
  eval "$(pyenv init -)"

fi

