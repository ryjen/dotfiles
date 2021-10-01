
type pip2 >/dev/null 2>&1

if [ $? -eq 0 ]; then
  pip2 install taskwarrior-time-tracking-hook
fi

type pip3 >/dev/null 2>&1

if [ $? -eq 0 ]; then
  pip3 install taskwarrior-time-tracking-hook
fi

TIMETRACKING_HOOK=$(which taskwarrior_time_tracking_hook)

if [ -e $TIMETRACKING_HOOK ]; then
  ln -sf $TIMETRACKING_HOOK ~/.task/hooks/on-modify.timetracking
fi

type timew >/dev/null 2>&1

if [ $? -eq 0 ]; then 
  mkdir -p ~/.task/hooks >/dev/null 2>&1
  ln -sf /usr/share/doc/timew/ext/on-modify.timewarrior ~/.task/hooks/
fi
