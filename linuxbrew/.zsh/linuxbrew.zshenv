
LINUXBREW_HOME=/home/linuxbrew/.linuxbrew

if [ -d $LINUXBREW_HOME ]; then

  export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
  export MANPATH="/home/linuxbrew/.linuxbrew/share/man:$MANPATH"
  export INFOPATH="/home/linuxbrew/.linuxbrew/share/info:$INFOPATH"            -

fi
