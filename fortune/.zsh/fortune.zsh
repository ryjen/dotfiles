
if type_exists fortune; then

  if type_exists cowsay; then
    fortune -s | cowsay -f small
  else
    fortune
  fi

fi
