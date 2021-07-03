
type_exists pip2

if [ $? -eq 0 ]; then
  pip2 install taskwarrior-time-tracking-hook
fi

type_exists pip3

if [ $? -eq 0 ] then
  pip3 install taskwarrior-time-tracking-hook
fi