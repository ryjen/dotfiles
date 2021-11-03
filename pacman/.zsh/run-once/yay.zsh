type yay >/dev/null

if [ $? -ne 0 ]; then
  exit
fi

packages=(
  modd
  starship
)

# check all installed
# TODO: do this only once and unlink
yay -Q ${packages[@]} 2>&1 >/dev/null

if [ $? -ne 0 ]; then
  echo "Installing system packages"
  yay -S ${packages[@]}

  if [ $? -ne 0 ]; then
    exit 1
  fi
fi

rm -f ${(%):-%N}

