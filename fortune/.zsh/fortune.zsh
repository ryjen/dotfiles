
if command_exists fortune; then

  if command_exists cowsay; then
    fortune -s | cowsay
  else
    fortune
  fi

fi
