
if type_exists fortune; then

  if type_exists cowsay; then
    if type_exists lolcat; then
      fortune -s | cowsay -f small | lolcat
    else
      fortune -s | cowsay -f small
    fi
  else
    if type_exists lolcat; then
      fortune -s | lolcat
    else
      fortune
    fi
  fi

fi
