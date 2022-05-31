
KEYFILE=$HOME/.ssh/id_rsa
if [ ! -s $KEYFILE ]; then
  ssh-keygen -f $KEYFILE -N ""
fi