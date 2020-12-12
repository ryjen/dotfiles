#!/bin/bash
# found this code on http://taskwarrior.org/projects/1/wiki/Export-htmlpy
# For cron: */30 * * * * DISPLAY=:0.0 /home/User/configs/TaskNotify.sh
# Requires linux with notify-send and canberra-gtk-play which are default on Ubuntu

num=`task active | wc -l`
if [ $num -gt "1" ]
  then
    notify-send "Active Tasks" "`task active | tail -n +3 | head -n -1`" 
    play /usr/share/sounds/freedesktop/stereo/bell.oga
  else
    notify-send "No Active Tasks" "C'mon! What are you doing?" 
    play /usr/share/sounds/ubuntu/stereo/dialog-question.ogg
  fi