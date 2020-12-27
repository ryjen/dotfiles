
if type_exists fortune; then

  if type_exists cowsay; then
    fortune -s | cowsay
  else
    fortune
  fi

fi
