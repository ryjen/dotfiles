
packages=(
  diff-so-fancy
)

# check all installed
# TODO: do this only once and unlink
pacman -Qs ${packages[@]} >/dev/null

if [ $? -ne 0 ]; then
  echo "Installing system packages"
  sudo pacman -S ${packages[@]}

  rm -f $HOME/.zsh/pacman.zsh
fi


