SNAP_BIN=/snap/bin

if [ -d $SNAP_BIN ]; then
  PATH=$PATH:$SNAP_BIN
fi

