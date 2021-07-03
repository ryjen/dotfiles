
type pip2 2>&1 >/dev/null

if [ $? -eq 0 ]; then
  pip2 install taskwarrior-time-tracking-hook
fi

type pip3 2>&1 >/dev/null

if [ $? -eq 0 ] then
  pip3 install taskwarrior-time-tracking-hook
fi